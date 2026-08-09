"""Conservative garbage collection for qemount build state."""

import logging
import shutil
import subprocess
from pathlib import Path


log = logging.getLogger(__name__)

QEMOUNT_LABEL = "org.qemount.input-hash"


def _podman_lines(arguments: list[str]) -> list[str]:
    result = subprocess.run(
        ["podman", *arguments], capture_output=True, text=True, check=False
    )
    if result.returncode != 0:
        message = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(message or "podman command failed")
    return [line for line in result.stdout.splitlines() if line]


def active_qemount_containers() -> list[str]:
    """Return running containers created from qemount-labelled images."""
    return _podman_lines(
        [
            "ps",
            "--filter",
            f"label={QEMOUNT_LABEL}",
            "--format",
            "{{.ID}}",
        ]
    )


def obsolete_qemount_images() -> list[str]:
    """Return untagged images owned by qemount, newest occurrence once."""
    lines = _podman_lines(
        [
            "images",
            "--filter",
            f"label={QEMOUNT_LABEL}",
            "--format",
            "{{.ID}}\t{{.Repository}}\t{{.Tag}}",
        ]
    )
    return parse_obsolete_images(lines)


def parse_obsolete_images(lines: list[str]) -> list[str]:
    """Extract unique untagged image IDs from formatted Podman output."""
    images = []
    seen = set()
    for line in lines:
        image_id, repository, tag = line.split("\t", 2)
        if repository != "<none>" or tag != "<none>" or image_id in seen:
            continue
        seen.add(image_id)
        images.append(image_id)
    return images


def orphaned_provider_caches(build_dir: Path, live_names: set[str]) -> list[Path]:
    """Return automatic provider caches absent from the current catalogue."""
    stages = build_dir / "cache" / "stages"
    if not stages.exists():
        return []
    orphans = []
    for build_platform in stages.iterdir():
        if not build_platform.is_dir():
            continue
        orphans.extend(
            path
            for path in build_platform.iterdir()
            if path.is_dir() and path.name not in live_names
        )
    return sorted(orphans)


def collect(
    build_dir: Path, live_cache_names: set[str], dry_run: bool = False
) -> tuple[int, int]:
    """Collect qemount-owned disposable state and return item counts."""
    active = active_qemount_containers()
    if active:
        raise RuntimeError(
            "qemount build containers are running; wait for them before running gc"
        )

    images = obsolete_qemount_images()
    provider_caches = orphaned_provider_caches(build_dir, live_cache_names)

    for path in provider_caches:
        log.debug("GC provider cache: %s", path)
        if not dry_run:
            shutil.rmtree(path)

    if images:
        for image_id in images:
            log.debug("GC image: %s", image_id)
        if not dry_run:
            result = subprocess.run(
                ["podman", "image", "rm", *images], check=False
            )
            if result.returncode != 0:
                raise RuntimeError("podman could not remove every obsolete image")

    return len(images), len(provider_caches)
