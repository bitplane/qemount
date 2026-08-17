"""
Build runner for mountin build system.

Executes build steps in dependency order using podman.
"""

import json
import logging
import os
import re
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime
from pathlib import Path
from typing import TextIO

from .catalogue import build_graph
from .provider_cache import provider_cache_relative, remove_provider_cache
from .cache import (
    image_is_current,
    load_cache,
    save_cache,
    hash_path_inputs,
    is_output_dirty,
    update_output_hash,
    update_image_hash,
)

log = logging.getLogger(__name__)

DOCKER_ARG_PATTERN = re.compile(r"^\s*ARG\s+([A-Za-z_][A-Za-z0-9_]*)", re.MULTILINE)


def podman_runtime_args(kvm_device: Path = Path("/dev/kvm")) -> list[str]:
    """Return optional host acceleration arguments for container runs."""
    if not kvm_device.exists() or not os.access(kvm_device, os.R_OK | os.W_OK):
        return []

    return ["--device", str(kvm_device), "--group-add", "keep-groups"]


def stop_process(proc: subprocess.Popen) -> None:
    """Stop and reap a child process without leaving it orphaned."""
    if proc.poll() is not None:
        return

    proc.terminate()
    try:
        proc.wait(timeout=5)
    except subprocess.TimeoutExpired:
        proc.kill()
        proc.wait()


def container_cid_path(build_dir: Path) -> Path:
    """Reserve a unique, initially absent path for a Podman CID file."""
    cid_dir = build_dir / "cache" / "containers"
    cid_dir.mkdir(parents=True, exist_ok=True)
    descriptor, name = tempfile.mkstemp(prefix="run.", suffix=".cid", dir=cid_dir)
    os.close(descriptor)
    path = Path(name)
    path.unlink()
    return path


def remove_container(cid_path: Path) -> None:
    """Force-remove the container recorded by Podman, if it still exists."""
    try:
        container_id = cid_path.read_text().strip()
    except FileNotFoundError:
        return

    if container_id:
        subprocess.run(
            ["podman", "rm", "--force", container_id],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )


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


def get_image_input_hash(tag: str) -> str | None:
    """Read mountin's input identity from a locally stored image."""
    result = subprocess.run(
        [
            "podman",
            "image",
            "inspect",
            tag,
            "--format",
            '{{index .Labels "org.mountin.input-hash"}}',
        ],
        capture_output=True,
        text=True,
    )
    return result.stdout.strip() if result.returncode == 0 else None


def build_log_path(build_dir: Path, stage: str, phase: str) -> Path:
    """Return the persistent log path for a catalogue stage and command phase."""
    stage_path = Path(stage)
    return build_dir / "logs" / stage_path.parent / f"{stage_path.name}.{phase}.log"


def run_streaming(
    cmd: list[str],
    log_path: Path,
    cwd: Path | None = None,
    stream: TextIO | None = None,
) -> int:
    """Run a command while teeing its combined output to the terminal and a log."""
    if stream is None:
        stream = sys.stderr

    log_path.parent.mkdir(parents=True, exist_ok=True)
    with log_path.open("w", encoding="utf-8", errors="replace") as log_file:
        started = datetime.now().astimezone().isoformat()
        log_file.write(f"[mountin] started: {started}\n")
        log_file.flush()

        proc = subprocess.Popen(
            cmd,
            cwd=cwd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            errors="replace",
            bufsize=1,
        )

        last_line_had_newline = True
        interrupted = False
        try:
            assert proc.stdout is not None
            for line in proc.stdout:
                stream.write(line)
                stream.flush()
                log_file.write(line)
                log_file.flush()
                last_line_had_newline = line.endswith("\n")

            returncode = proc.wait()
        except BaseException:
            interrupted = True
            stop_process(proc)
            raise
        finally:
            if not last_line_had_newline:
                stream.write("\n")
                stream.flush()
                log_file.write("\n")

            finished = datetime.now().astimezone().isoformat()
            log_file.write(f"[mountin] finished: {finished}\n")
            if interrupted:
                log_file.write("[mountin] interrupted\n")
            else:
                log_file.write(f"[mountin] exit status: {returncode}\n")

    return returncode


def build_image(
    stage: str,
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
    log.info(
        "Building image for %s: %s%s",
        stage,
        tag,
        " (no-cache)" if no_cache else "",
    )
    cmd = ["podman", "build"]
    cmd.extend(["--label", "org.mountin.managed=true"])

    if no_cache:
        cmd.append("--no-cache")

    cache_dir = build_dir / "cache"
    cache_dir.mkdir(parents=True, exist_ok=True)
    cmd.extend(["--volume", f"{cache_dir.absolute()}:/host/build/cache:rw"])
    provider_cache = build_dir / "cache" / provider_cache_relative(env["BUILD_PLATFORM"], stage) / "work"
    provider_cache.mkdir(parents=True, exist_ok=True)
    cmd.extend(["--volume", f"{provider_cache.absolute()}:/cache:rw"])

    # Mount build_requires as volumes
    for req in build_requires:
        src = build_dir / req
        dest = Path("/host/build") / req
        cmd.extend(["--volume", f"{src.absolute()}:{dest}:ro"])

    declared_args = dockerfile_build_args(context_dir / "Dockerfile")
    for key, value in env.items():
        if key in declared_args:
            cmd.extend(["--build-arg", f"{key}={value}"])
    cmd.extend(["-t", tag, "."])

    log_path = build_log_path(build_dir, stage, "image")
    returncode = run_streaming(cmd, log_path, cwd=context_dir)
    if returncode != 0:
        log.error("Build failed: %s", stage)
        log.error("Log: %s", log_path)
        return None

    image_id = get_image_id(tag)
    if not image_id:
        log.error("Image was not created: %s", tag)
        log.error("Log: %s", log_path)
        return None
    return image_id


def dockerfile_build_args(dockerfile: Path) -> set[str]:
    """Return build argument names explicitly declared by a Dockerfile."""
    return set(DOCKER_ARG_PATTERN.findall(dockerfile.read_text()))


def run_container(
    stage: str,
    image: str,
    build_dir: Path,
    env: dict,
    targets: list[str],
) -> tuple[bool, Path]:
    """Run a container with the given environment.

    Targets are passed as positional args to the container entrypoint.
    Build scripts use these to filter which outputs to build.

    Returns (success, log_path).
    """
    cid_path = container_cid_path(build_dir)
    cmd = ["podman", "run", "--rm", "--cidfile", str(cid_path)]
    cmd.extend(podman_runtime_args())
    cmd.extend(["-v", f"{build_dir.absolute()}:/host/build"])
    provider_cache = build_dir / "cache" / provider_cache_relative(env["BUILD_PLATFORM"], stage) / "work"
    provider_cache.mkdir(parents=True, exist_ok=True)
    cmd.extend(["-v", f"{provider_cache.absolute()}:/cache"])
    for key, value in env.items():
        cmd.extend(["-e", f"{key}={value}"])
    cmd.append(image)
    cmd.extend(targets)

    log.info("Running stage %s: %s", stage, image)
    log_path = build_log_path(build_dir, stage, "run")
    try:
        returncode = run_streaming(cmd, log_path)
    finally:
        remove_container(cid_path)
        cid_path.unlink(missing_ok=True)
    if returncode != 0:
        log.error("Build failed: %s", stage)
        log.error("Log: %s", log_path)
    return returncode == 0, log_path


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


def local_image_tag(path: str, output_platform: str | None) -> str:
    """Return a valid, variant-specific local container image tag."""
    tag = f"localhost/{path}".lower()
    return f"{tag}:{output_platform}" if output_platform else tag


def output_backup(path: Path) -> Path:
    """Return the transaction backup path beside an output."""
    return path.with_name(f"{path.name}.mountin-previous")


def output_exists(path: Path) -> bool:
    """Return whether an output path or symlink occupies this name."""
    return path.exists() or path.is_symlink()


def remove_output(path: Path) -> None:
    """Remove a file, symlink or directory output without following links."""
    if path.is_dir() and not path.is_symlink():
        shutil.rmtree(path)
    else:
        path.unlink()


def prepare_provider_cache(build_dir: Path, build_platform: str, instance_id: str, input_hash: str) -> Path:
    """Make a provider's private cache match its complete input identity."""
    cache_root = build_dir / "cache" / provider_cache_relative(build_platform, instance_id)
    marker = cache_root / ".mountin-input"
    try:
        current = marker.read_text().strip()
    except FileNotFoundError:
        current = None

    if current != input_hash:
        if cache_root.exists():
            remove_provider_cache(build_dir, cache_root)
        cache_root.mkdir(parents=True)
        temporary = cache_root / ".mountin-input.tmp"
        temporary.write_text(f"{input_hash}\n")
        temporary.replace(marker)

    work_dir = cache_root / "work"
    work_dir.mkdir(exist_ok=True)
    return work_dir


def begin_output_transaction(build_dir: Path, outputs: list[str]) -> dict[str, Path]:
    """Preserve previous outputs until their replacements are verified."""
    backups = {}
    for output in outputs:
        path = build_dir / output
        backup = output_backup(path)
        if output_exists(backup):
            if output_exists(path):
                remove_output(path)
            backup.rename(path)
        if output_exists(path):
            path.rename(backup)
            backups[output] = backup
    return backups


def finish_output_transaction(build_dir: Path, outputs: list[str], backups: dict[str, Path], success: bool) -> None:
    """Commit generated outputs or restore the previous valid files."""
    for output in outputs:
        path = build_dir / output
        backup = backups.get(output)
        if success:
            if backup and output_exists(backup):
                remove_output(backup)
            continue
        if output_exists(path):
            remove_output(path)
        if backup and output_exists(backup):
            backup.rename(path)


def image_needs_no_cache(force: bool, build_requires: list[str]) -> bool:
    """Return whether Podman's layer cache must be bypassed.

    Podman does not include bind-mounted build inputs in a RUN instruction's
    cache key. The mountin cache detects changes to build_requires, but a
    subsequent podman build could otherwise reuse a layer built from stale
    mounted content.
    """
    return force or bool(build_requires)


def validate_path_provides(
    path: str,
    docker_tags: list,
    file_outputs: list,
    has_dockerfile: bool,
    runs_on_tag: str | None,
) -> str | None:
    """
    Validate that a path's provides are buildable.

    Returns error message if invalid, None if valid.
    """
    if docker_tags and not has_dockerfile:
        return f"{path} provides docker image but has no Dockerfile"
    if file_outputs and not has_dockerfile and not runs_on_tag:
        return f"{path} provides files but has no Dockerfile or runs_on"
    return None


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

    for instance_id in graph["order"]:
        record = graph["nodes"][instance_id]
        path = record["provider"]
        instance_context = {**record["context"], "SELF": path}
        meta = record["meta"].copy()
        platform_env = {
            key: value
            for key, value in instance_context.items()
            if key.startswith("BUILD_") or key.startswith("OUTPUT_")
        }
        env = {**platform_env, **meta.get("env", {})}
        meta["env"] = env

        provides = list(meta.get("provides", {}).keys())
        if not provides:
            continue

        docker_tags = get_docker_provides(provides)
        file_outputs = get_file_provides(provides)
        needed_outputs = get_file_provides(graph["needed"].get(instance_id, []))
        dockerfile = pkg_dir / path / "Dockerfile"
        runs_on_tag = get_image_tag(meta)
        build_requires = list(meta.get("build_requires", {}).keys())

        # Compute input hash for this path (Merkle tree)
        provenance = {
            "provider": path,
            "provider_instance": instance_id,
            "build_platform": context.get("BUILD_PLATFORM"),
            "output_platform": record.get("output_platform"),
        }
        input_hash = hash_path_inputs(path, pkg_dir, meta, dep_hashes, build_dir, cache)
        prepare_provider_cache(build_dir, context["BUILD_PLATFORM"], instance_id, input_hash)
        dep_hashes[instance_id] = input_hash
        for provided in docker_tags:
            dep_hashes[provided] = input_hash

        # Validate provides are buildable
        error = validate_path_provides(path, docker_tags, file_outputs, dockerfile.exists(), runs_on_tag)
        if error:
            log.error(error)
            return False

        # Build image if Dockerfile exists
        if dockerfile.exists():
            tag = docker_tags[0] if docker_tags else local_image_tag(path, record["output_platform"])
            # Container stores are machine-local even when build/ is shared.
            image_id = get_image_id(tag)
            current = image_is_current(cache, context["BUILD_PLATFORM"], tag, image_id, input_hash)
            # One-time migration from images built before image identity moved
            # out of the Dockerfile layer cache key.
            if not current and image_id and get_image_input_hash(tag) == input_hash:
                update_image_hash(cache, context["BUILD_PLATFORM"], tag, image_id, input_hash)
                save_cache(build_dir, cache)
                current = True
            if not force and current:
                log.info("Clean: %s (image)", tag)
            else:
                image_id = build_image(
                    instance_id,
                    dockerfile.parent,
                    tag,
                    env,
                    build_requires,
                    build_dir,
                    no_cache=image_needs_no_cache(force, build_requires),
                )
                if not image_id:
                    return False
                update_image_hash(cache, context["BUILD_PLATFORM"], tag, image_id, input_hash)
                save_cache(build_dir, cache)

        # Done if no file outputs
        if not file_outputs:
            continue

        # Helper to get per-output requires
        def get_output_requires(output: str) -> list[str]:
            return meta.get("provides", {}).get(output, {}).get("requires", [])

        # Find dirty outputs (missing or hash changed)
        if force:
            dirty_outputs = needed_outputs
        else:
            dirty_outputs = [
                o for o in needed_outputs if is_output_dirty(o, input_hash, cache, build_dir, get_output_requires(o))
            ]

        if not dirty_outputs:
            log.info("Clean: %s", path)
            for output_name in file_outputs:
                if output_name in cache and (build_dir / output_name).exists():
                    dep_hashes[output_name] = cache[output_name]["hash"]
            continue

        # Use runs_on tag if no Dockerfile was built
        if runs_on_tag:
            tag = runs_on_tag

        backups = begin_output_transaction(build_dir, dirty_outputs)

        # Run container to produce file outputs
        env["META"] = json.dumps(meta)
        success, log_path = run_container(instance_id, tag, build_dir, env, dirty_outputs)
        if not success:
            finish_output_transaction(build_dir, dirty_outputs, backups, False)
            return False

        # Verify dirty outputs were created and update cache
        missing = [o for o in dirty_outputs if not (build_dir / o).exists()]
        if missing:
            finish_output_transaction(build_dir, dirty_outputs, backups, False)
            for output_name in missing:
                log.error("Output was not created: %s", output_name)
            log.error("Log: %s", log_path)
            return False

        finish_output_transaction(build_dir, dirty_outputs, backups, True)
        for output_name in dirty_outputs:
            update_output_hash(
                cache,
                output_name,
                input_hash,
                build_dir,
                get_output_requires(output_name),
                provenance,
            )
        for output_name in file_outputs:
            if output_name in cache and (build_dir / output_name).exists():
                dep_hashes[output_name] = cache[output_name]["hash"]
        # Save cache after each successful build step
        save_cache(build_dir, cache)

    log.info("Build complete")
    return True
