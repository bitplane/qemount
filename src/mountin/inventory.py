"""Inventory concrete build artefacts without claiming reproducibility."""

import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

from .cache import load_cache
from .catalogue import build_output_index


SCHEMA_VERSION = 1
ARTEFACT_ROOTS = ("bin", "data", "lib", "sources")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def create_inventory(catalogue: dict, context: dict, build_dir: Path) -> tuple[dict, list[str]]:
    """Describe known catalogue outputs which actually exist in build/."""
    outputs = build_output_index(catalogue, context, build_dir)
    cache = load_cache(build_dir)
    artefacts = []

    for output, record in sorted(outputs.items()):
        if output.startswith("docker:"):
            continue
        path = build_dir / output
        if not path.is_file():
            continue
        cached = cache.get(output, {})
        provenance = cached.get("provenance", {})
        artefacts.append(
            {
                "path": output,
                "provider": record["provider"],
                "provider_instance": record["id"],
                "output_platform": record["output_platform"],
                "build_platform": provenance.get("build_platform"),
                "size": path.stat().st_size,
                "sha256": sha256_file(path),
                "input_hash": cached.get("input_hash"),
            }
        )

    known = {item["path"] for item in artefacts}
    unknown = []
    for root_name in ARTEFACT_ROOTS:
        root = build_dir / root_name
        if not root.exists():
            continue
        for path in root.rglob("*"):
            if path.is_file():
                relative = str(path.relative_to(build_dir))
                if relative not in known:
                    unknown.append(relative)

    inventory = {
        "schema": SCHEMA_VERSION,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "build_platform": context["MOUNTIN_BUILD_PLATFORM"],
        "artefacts": artefacts,
    }
    return inventory, sorted(unknown)


def write_inventory(inventory: dict, destination: Path) -> None:
    """Publish an inventory atomically."""
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_suffix(f"{destination.suffix}.tmp")
    temporary.write_text(json.dumps(inventory, indent=2, sort_keys=True) + "\n")
    temporary.replace(destination)
