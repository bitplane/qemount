"""Conservative garbage collection for qemount build state."""

import logging
import json
import shutil
import subprocess
from pathlib import Path


log = logging.getLogger(__name__)

QEMOUNT_LABEL = "org.qemount.input-hash"
CACHE_MANIFEST_DIR = ".qemount/manifests"
CACHE_MANIFEST_SCHEMA = 1
CACHE_GENERATION_MARKER = ".qemount-generation"


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


def obsolete_cache_generations(build_dir: Path) -> list[Path]:
    """Return superseded generations registered by cache-owning builders."""
    cache_dir = (build_dir / "cache").resolve()
    manifest_dir = cache_dir / CACHE_MANIFEST_DIR
    if not manifest_dir.exists():
        return []

    obsolete = []
    for manifest_path in sorted(manifest_dir.glob("*.json")):
        try:
            manifest = json.loads(manifest_path.read_text())
            if manifest.get("schema") != CACHE_MANIFEST_SCHEMA:
                raise ValueError("unsupported schema")
            owner = manifest["owner"]
            root_name = Path(manifest["root"])
            current_name = Path(manifest["current"])
            if (
                not owner
                or root_name.is_absolute()
                or current_name.is_absolute()
                or len(current_name.parts) != 1
            ):
                raise ValueError("invalid owner or path")
            root = (cache_dir / root_name).resolve()
            if not root.is_relative_to(cache_dir) or not root.is_dir():
                raise ValueError("cache root is absent or escapes build/cache")
            current = (root / current_name).resolve()
            if current.parent != root or not current.is_dir():
                raise ValueError("current generation is absent or escapes its root")
            if (current / CACHE_GENERATION_MARKER).read_text().strip() != owner:
                raise ValueError("current generation owner does not match")

            for generation in root.iterdir():
                if not generation.is_dir() or generation.resolve() == current:
                    continue
                marker = generation / CACHE_GENERATION_MARKER
                if marker.is_file() and marker.read_text().strip() == owner:
                    obsolete.append(generation)
        except (KeyError, OSError, ValueError, json.JSONDecodeError) as error:
            log.warning("Ignoring invalid cache manifest %s: %s", manifest_path, error)

    return obsolete


def collect(build_dir: Path, dry_run: bool = False) -> tuple[int, int, int]:
    """Collect qemount-owned disposable state and return item counts."""
    active = active_qemount_containers()
    if active:
        raise RuntimeError(
            "qemount build containers are running; wait for them before running gc"
        )

    images = obsolete_qemount_images()
    work_directories = abandoned_work_directories(build_dir)
    cache_generations = obsolete_cache_generations(build_dir)

    for path in cache_generations:
        log.debug("GC cache generation: %s", path)
        if not dry_run:
            shutil.rmtree(path)

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

    return len(images), len(work_directories), len(cache_generations)
