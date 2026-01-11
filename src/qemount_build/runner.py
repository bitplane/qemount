"""
Build runner for qemount build system.

Executes build steps in dependency order using podman.
"""

import json
import logging
import subprocess
from pathlib import Path

from .catalogue import resolve_path, build_graph

log = logging.getLogger(__name__)


def image_exists(tag: str) -> bool:
    """Check if a container image exists."""
    result = subprocess.run(
        ["podman", "image", "exists", tag],
        capture_output=True,
    )
    return result.returncode == 0


def build_image(context_dir: Path, tag: str, env: dict) -> bool:
    """Build a container image."""
    log.info("Building image: %s", tag)
    cmd = ["podman", "build"]
    for key, value in env.items():
        cmd.extend(["--build-arg", f"{key}={value}"])
    cmd.extend(["-t", tag, "."])
    result = subprocess.run(cmd, cwd=context_dir)
    if result.returncode != 0:
        return False
    if not image_exists(tag):
        log.error("Image was not created: %s", tag)
        return False
    return True


def run_container(image: str, build_dir: Path, env: dict) -> bool:
    """Run a container with the given environment."""
    cmd = ["podman", "run", "--rm", "-v", f"{build_dir.absolute()}:/host/build"]
    for key, value in env.items():
        cmd.extend(["-e", f"{key}={value}"])
    cmd.append(image)

    log.info("Running: %s", image)
    result = subprocess.run(cmd)
    return result.returncode == 0


def get_image_tag(resolved: dict) -> str | None:
    """Extract image tag from runs_on, stripping docker: prefix."""
    runs_on = resolved.get("runs_on")
    if not runs_on:
        return None
    if not runs_on.startswith("docker:"):
        raise ValueError(f"runs_on must start with 'docker:', got: {runs_on}")
    return runs_on[7:]


def get_docker_provides(provides: list) -> list:
    """Get docker: provides, stripping prefix."""
    return [p[7:] for p in provides if p.startswith("docker:")]


def get_file_provides(provides: list) -> list:
    """Get non-docker provides."""
    return [p for p in provides if not p.startswith("docker:")]


def run_build(
    target: str,
    catalogue: dict,
    context: dict,
    build_dir: Path,
    pkg_dir: Path,
    force: bool = False,
) -> bool:
    """
    Build a target and all its dependencies.

    Rules:
    - docker: provides requires a Dockerfile
    - file provides requires either Dockerfile or runs_on
    - runs_on specifies which image to use when no Dockerfile
    """
    graph = build_graph(target, catalogue, context)

    for path in graph["order"]:
        path_context = {**context, "SELF": path}
        resolved = resolve_path(path, catalogue, path_context)
        meta = graph["nodes"][path]
        env = resolved.get("env", {})

        provides = list(meta.get("provides", {}).keys())
        if not provides:
            continue

        docker_tags = get_docker_provides(provides)
        file_outputs = get_file_provides(provides)
        dockerfile = pkg_dir / path / "Dockerfile"
        runs_on_tag = get_image_tag(resolved)

        # Validate: docker provides requires Dockerfile
        if docker_tags and not dockerfile.exists():
            log.error("%s provides docker image but has no Dockerfile", path)
            return False

        # Validate: file provides requires Dockerfile or runs_on
        if file_outputs and not dockerfile.exists() and not runs_on_tag:
            log.error("%s provides files but has no Dockerfile or runs_on", path)
            return False

        # Build image if Dockerfile exists
        if dockerfile.exists():
            tag = docker_tags[0] if docker_tags else f"localhost/{path}"
            if not build_image(dockerfile.parent, tag, env):
                return False

        # Done if no file outputs
        if not file_outputs:
            continue

        # Check if outputs already exist
        if not force and all((build_dir / o).exists() for o in file_outputs):
            log.info("Exists: %s", ", ".join(file_outputs))
            continue

        # Use runs_on tag if no Dockerfile was built
        if runs_on_tag:
            tag = runs_on_tag

        # Run container to produce file outputs
        env["META"] = json.dumps(meta)
        if not run_container(tag, build_dir, env):
            log.error("Failed to run: %s", path)
            return False

        # Verify outputs
        for output in file_outputs:
            if not (build_dir / output).exists():
                log.error("Output was not created: %s", output)
                return False

    log.info("Build complete")
    return True
