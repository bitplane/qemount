"""
Build runner for qemount build system.

Executes build steps in dependency order using podman.
"""

import json
import subprocess
from pathlib import Path

from .catalogue import resolve_path, build_graph


def image_exists(tag: str) -> bool:
    """Check if a container image exists."""
    result = subprocess.run(
        ["podman", "image", "exists", tag],
        capture_output=True,
    )
    return result.returncode == 0


def build_image(context_dir: Path, tag: str, arch: str, host_arch: str) -> bool:
    """Build a container image."""
    print(f"Building image: {tag}")
    result = subprocess.run(
        [
            "podman", "build",
            "--build-arg", f"ARCH={arch}",
            "--build-arg", f"HOST_ARCH={host_arch}",
            "-t", tag, ".",
        ],
        cwd=context_dir,
    )
    if result.returncode != 0:
        return False
    if not image_exists(tag):
        print(f"Failed: image {tag} was not created")
        return False
    return True


def run_container(image: str, build_dir: Path, env: dict) -> bool:
    """Run a container with the given environment."""
    cmd = ["podman", "run", "--rm", "-v", f"{build_dir.absolute()}:/host/build"]
    for key, value in env.items():
        # Skip unresolved variables to avoid breaking container env
        if "${" in str(value):
            continue
        cmd.extend(["-e", f"{key}={value}"])
    cmd.append(image)

    print(f"Running: {image}")
    result = subprocess.run(cmd)
    return result.returncode == 0


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

    Every path with provides must have a Dockerfile.
    - docker:* provides → build image only
    - other provides → build image, run it, verify outputs
    """
    graph = build_graph(target, catalogue, context)

    for path in graph["order"]:
        meta = graph["nodes"][path]
        provides = list(meta.get("provides", {}).keys())

        if not provides:
            print(f"Skipping {path}: no provides")
            continue

        # Check for Dockerfile
        dockerfile_dir = pkg_dir / path
        if not (dockerfile_dir / "Dockerfile").exists():
            print(f"Error: {path} has provides but no Dockerfile")
            return False

        # Separate docker outputs from file outputs
        docker_outputs = [p for p in provides if p.startswith("docker:")]
        file_outputs = [p for p in provides if not p.startswith("docker:")]

        # Build the image
        # Tag is either the docker: output or the path itself
        if docker_outputs:
            tag = docker_outputs[0][7:]  # strip docker: prefix
        else:
            tag = path

        if not build_image(
            dockerfile_dir,
            tag,
            context["ARCH"],
            context["HOST_ARCH"],
        ):
            print(f"Failed to build image for: {path}")
            return False

        # If there are file outputs, run the container to produce them
        if file_outputs:
            # Check if outputs already exist
            all_exist = all(
                (build_dir / output).exists() for output in file_outputs
            )
            if not force and all_exist:
                print(f"Exists: {', '.join(file_outputs)}")
                continue

            # Build env from resolved metadata
            resolved = resolve_path(path, catalogue, context)
            env = resolved.get("env", {})
            env["META"] = json.dumps(meta)

            if not run_container(tag, build_dir, env):
                print(f"Failed to run: {path}")
                return False

            # Verify outputs were created
            for output in file_outputs:
                if not (build_dir / output).exists():
                    print(f"Failed: {output} was not created")
                    return False

    print("Build complete")
    return True
