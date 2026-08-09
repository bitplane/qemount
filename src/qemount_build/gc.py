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


def abandoned_work_directories(build_dir: Path) -> list[Path]:
    """Return transactional work directories left by interrupted builds."""
    cache = build_dir / "cache" / "9front"
    if not cache.exists():
        return []
    return sorted(path for path in cache.rglob("run.*") if path.is_dir())


def collect(build_dir: Path, dry_run: bool = False) -> tuple[int, int]:
    """Collect qemount-owned disposable state and return item counts."""
    active = active_qemount_containers()
    if active:
        raise RuntimeError(
            "qemount build containers are running; wait for them before running gc"
        )

    images = obsolete_qemount_images()
    work_directories = abandoned_work_directories(build_dir)

    for path in work_directories:
        log.debug("GC work directory: %s", path)
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

    return len(images), len(work_directories)
