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


def get_dockerfile_dir(path: str, pkg_dir: Path) -> Path:
    """Get directory containing Dockerfile for a catalogue path."""
    candidate = pkg_dir / path
    if (candidate / "Dockerfile").exists():
        return candidate
    raise FileNotFoundError(f"No Dockerfile found for {path}")


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

    Returns True on success, False on failure.
    """
    graph = build_graph(target, catalogue, context)

    for path in graph["order"]:
        meta = graph["nodes"][path]
        provides = list(meta.get("provides", {}).keys())

        if not provides:
            print(f"Skipping {path}: no provides")
            continue

        output = provides[0]

        # Docker image build
        if output.startswith("docker:"):
            tag = output[7:]
            dockerfile_dir = get_dockerfile_dir(path, pkg_dir)

            if not build_image(
                dockerfile_dir,
                tag,
                context.get("ARCH", "x86_64"),
                context.get("HOST_ARCH", "x86_64"),
            ):
                print(f"Failed to build: {tag}")
                return False

        # Regular build step - run container
        else:
            output_path = build_dir / output
            if not force and output_path.exists():
                print(f"Exists: {output}")
                continue

            requires = list(meta.get("requires", {}).keys())
            docker_req = next((r for r in requires if r.startswith("docker:")), None)
            if not docker_req:
                print(f"No docker requirement for {path}")
                return False

            image = docker_req[7:]

            # Build env from resolved metadata
            resolved = resolve_path(path, catalogue, context)
            env = resolved.get("env", {})
            env["META"] = json.dumps(meta)

            if not run_container(image, build_dir, env):
                print(f"Failed to run: {path}")
                return False

            if not output_path.exists():
                print(f"Failed: {output} was not created")
                return False

    print("Build complete")
    return True
