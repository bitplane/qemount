"""
Build runner for qemount build system.

Executes build steps in dependency order using podman.
"""

import json
import logging
import subprocess
from pathlib import Path

from .catalogue import resolve_path, build_graph
from .cache import (
    load_cache,
    save_cache,
    hash_path_inputs,
    is_output_dirty,
    is_image_dirty,
    update_output_hash,
    update_image_hash,
)

log = logging.getLogger(__name__)


def image_exists(tag: str) -> bool:
    """Check if a container image exists."""
    result = subprocess.run(
        ["podman", "image", "exists", tag],
        capture_output=True,
    )
    return result.returncode == 0


def get_image_id(tag: str) -> str | None:
    """Get the ID of a container image."""
    result = subprocess.run(
        ["podman", "image", "inspect", tag, "--format", "{{.Id}}"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return None
    return result.stdout.strip()


def build_image(
    context_dir: Path,
    tag: str,
    env: dict,
    build_requires: list[str],
    build_dir: Path,
    no_cache: bool = False,
) -> str | None:
    """Build a container image.

    Mounts build_requires paths from build_dir into the build context
    as read-only volumes.

    Returns the image ID on success, None on failure.
    """
    log.info("Building image: %s%s", tag, " (no-cache)" if no_cache else "")
    cmd = ["podman", "build"]

    if no_cache:
        cmd.append("--no-cache")

    # Mount build_requires as volumes
    for req in build_requires:
        src = build_dir / req
        dest = Path("/host/build") / req
        cmd.extend(["--volume", f"{src.absolute()}:{dest}:ro"])

    for key, value in env.items():
        cmd.extend(["--build-arg", f"{key}={value}"])
    cmd.extend(["-t", tag, "."])
    result = subprocess.run(cmd, cwd=context_dir, capture_output=True, text=True, errors='replace')
    logger = log.error if result.returncode else log.debug
    logger("stdout: %s", result.stdout)
    logger("stderr: %s", result.stderr)
    if result.returncode != 0:
        return None
    image_id = get_image_id(tag)
    if not image_id:
        log.error("Image was not created: %s", tag)
        return None
    return image_id


def run_container(
    image: str,
    build_dir: Path,
    env: dict,
    targets: list[str],
) -> tuple[bool, str, str]:
    """Run a container with the given environment.

    Targets are passed as positional args to the container entrypoint.
    Build scripts use these to filter which outputs to build.

    Returns (success, stdout, stderr).
    """
    cmd = ["podman", "run", "--rm", "-v", f"{build_dir.absolute()}:/host/build"]
    for key, value in env.items():
        cmd.extend(["-e", f"{key}={value}"])
    cmd.append(image)
    cmd.extend(targets)

    log.info("Running: %s", image)
    result = subprocess.run(cmd, capture_output=True, text=True, errors='replace')
    logger = log.error if result.returncode else log.debug
    logger("stdout: %s", result.stdout)
    logger("stderr: %s", result.stderr)
    return result.returncode == 0, result.stdout, result.stderr


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
    targets: list[str],
    catalogue: dict,
    context: dict,
    build_dir: Path,
    pkg_dir: Path,
    force: bool = False,
) -> bool:
    """
    Build targets and all their dependencies.

    Rules:
    - docker: provides requires a Dockerfile
    - file provides requires either Dockerfile or runs_on
    - runs_on specifies which image to use when no Dockerfile

    Uses input hashing to skip builds when inputs haven't changed.
    """
    graph = build_graph(targets, catalogue, context, build_dir)
    cache = load_cache(build_dir)
    dep_hashes = {}  # path -> computed input hash

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
        needed_outputs = get_file_provides(graph["needed"].get(path, []))
        dockerfile = pkg_dir / path / "Dockerfile"
        runs_on_tag = get_image_tag(resolved)
        build_requires = list(resolved.get("build_requires", {}).keys())

        # Compute input hash for this path (Merkle tree)
        input_hash = hash_path_inputs(path, pkg_dir, resolved, dep_hashes, build_dir)
        dep_hashes[path] = input_hash

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

            # Skip podman entirely if image is clean
            if not force and not is_image_dirty(tag, input_hash, cache, image_exists):
                log.info("Clean: %s (image)", tag)
            else:
                image_id = build_image(
                    dockerfile.parent, tag, env, build_requires, build_dir,
                    no_cache=force,
                )
                if not image_id:
                    return False

                # Update cache with new image state and save immediately
                update_image_hash(cache, tag, input_hash, image_id)
                save_cache(build_dir, cache)

        # Done if no file outputs
        if not file_outputs:
            continue

        # Find dirty outputs (missing or hash changed)
        if force:
            dirty_outputs = needed_outputs
        else:
            dirty_outputs = [
                o for o in needed_outputs
                if is_output_dirty(o, input_hash, cache, build_dir)
            ]

        if not dirty_outputs:
            log.info("Clean: %s", path)
            continue

        # Use runs_on tag if no Dockerfile was built
        if runs_on_tag:
            tag = runs_on_tag

        # Remove dirty outputs before rebuilding
        for output in dirty_outputs:
            output_path = build_dir / output
            if output_path.exists():
                log.info("Removing stale: %s", output)
                output_path.unlink()

        # Run container to produce file outputs
        env["META"] = json.dumps(meta)
        success, stdout, stderr = run_container(tag, build_dir, env, dirty_outputs)
        if not success:
            log.error("Failed to run: %s", path)
            return False

        # Verify dirty outputs were created and update cache
        for output in dirty_outputs:
            if not (build_dir / output).exists():
                log.error("Output was not created: %s", output)
                log.error("Container stdout:\n%s", stdout)
                log.error("Container stderr:\n%s", stderr)
                return False
            update_output_hash(cache, output, input_hash)

        # Save cache after each successful build step
        save_cache(build_dir, cache)

    log.info("Build complete")
    return True
