"""Conservative garbage collection for mountin build state."""

import logging
import subprocess
from pathlib import Path

from .provider_cache import remove_provider_cache


log = logging.getLogger(__name__)

MOUNTIN_LABEL = "org.mountin.managed=true"


def _podman_lines(arguments: list[str]) -> list[str]:
    result = subprocess.run(
        ["podman", *arguments], capture_output=True, text=True, check=False
    )
    if result.returncode != 0:
        message = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(message or "podman command failed")
    return [line for line in result.stdout.splitlines() if line]


def active_mountin_containers() -> list[str]:
    """Return running containers created from mountin-labelled images."""
    return _podman_lines(
        [
            "ps",
            "--filter",
            f"label={MOUNTIN_LABEL}",
            "--format",
            "{{.ID}}",
        ]
    )


def obsolete_mountin_images() -> list[str]:
    """Return untagged images owned by mountin, newest occurrence once."""
    lines = _podman_lines(
        [
            "images",
            "--filter",
            f"label={MOUNTIN_LABEL}",
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


def remove_obsolete_images(images: list[str]) -> int:
    """Remove unreferenced images without disturbing retained containers."""
    removed = 0
    for image_id in images:
        result = subprocess.run(
            ["podman", "image", "rm", image_id],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode == 0:
            removed += 1
            continue
        message = result.stderr.strip() or result.stdout.strip()
        log.warning("Keeping obsolete image %s: %s", image_id, message)
    return removed


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
    """Collect mountin-owned disposable state and return item counts."""
    active = active_mountin_containers()
    if active:
        raise RuntimeError(
            "mountin build containers are running; wait for them before running gc"
        )

    images = obsolete_mountin_images()
    provider_caches = orphaned_provider_caches(build_dir, live_cache_names)

    for path in provider_caches:
        log.debug("GC provider cache: %s", path)
        if not dry_run:
            remove_provider_cache(build_dir, path)

    for image_id in images:
        log.debug("GC image: %s", image_id)
    removed_images = len(images) if dry_run else remove_obsolete_images(images)

    return removed_images, len(provider_caches)
