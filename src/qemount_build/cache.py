"""
Build cache for qemount build system.

Tracks input hashes to detect when outputs need rebuilding.
Uses a Merkle tree approach - each path's hash includes its dependency hashes,
so changes propagate up the dependency chain.
"""

import hashlib
import json
from pathlib import Path


CACHE_FILE = "cache/hashes.json"


def load_cache(build_dir: Path) -> dict:
    """Load hash cache from disk."""
    path = build_dir / CACHE_FILE
    if path.exists():
        return json.loads(path.read_text())
    return {}


def save_cache(build_dir: Path, cache: dict):
    """Save hash cache to disk atomically."""
    path = build_dir / CACHE_FILE
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(".tmp")
    tmp.write_text(json.dumps(cache, indent=2, sort_keys=True))
    tmp.rename(path)


def hash_files(directory: Path) -> str:
    """Hash all files in a directory recursively."""
    h = hashlib.md5()
    if not directory.exists():
        return h.hexdigest()

    for f in sorted(directory.rglob("*")):
        if f.is_file():
            # Include relative path to detect renames/moves
            rel = f.relative_to(directory)
            h.update(str(rel).encode())
            h.update(f.read_bytes())

    return h.hexdigest()


def hash_path_inputs(
    path: str,
    pkg_dir: Path,
    resolved: dict,
    dep_hashes: dict,
    build_dir: Path,
) -> str:
    """
    Compute input hash for a catalogue path.

    Includes:
    - All files in the path's directory (Dockerfile, build.sh, overlays)
    - Hashes of all requires (from dep_hashes, Merkle tree)
    - Hashes of all build_requires (files mounted during docker build)
    - Env vars
    """
    h = hashlib.md5()

    # Hash all files in build context
    context_dir = pkg_dir / path
    h.update(hash_files(context_dir).encode())

    # Hash dependency hashes (Merkle tree) or file contents
    for req in sorted(resolved.get("requires", {}).keys()):
        h.update(req.encode())
        if req in dep_hashes:
            h.update(dep_hashes[req].encode())
        elif (build_dir / req).exists():
            h.update((build_dir / req).read_bytes())

    # Hash build_requires (mounted during docker build)
    for req in sorted(resolved.get("build_requires", {}).keys()):
        h.update(req.encode())
        req_path = build_dir / req
        if req_path.exists():
            if req_path.is_file():
                h.update(req_path.read_bytes())
            elif req_path.is_dir():
                h.update(hash_files(req_path).encode())

    # Hash env vars
    env = resolved.get("env", {})
    if env:
        h.update(json.dumps(sorted(env.items())).encode())

    return h.hexdigest()


def is_output_dirty(
    output: str,
    input_hash: str,
    cache: dict,
    build_dir: Path,
) -> bool:
    """Check if a file output needs rebuilding."""
    # Output doesn't exist
    if not (build_dir / output).exists():
        return True

    # No stored hash or hash differs
    stored = cache.get(output)
    return stored is None or stored != input_hash


def is_image_dirty(
    tag: str,
    input_hash: str,
    cache: dict,
    image_exists_fn,
) -> bool:
    """
    Check if a docker image needs rebuilding.

    Returns True if input_hash changed or image doesn't exist.
    """
    cache_key = f"docker:{tag}"
    cached = cache.get(cache_key)

    if cached is None:
        return True

    if cached.get("input_hash") != input_hash:
        return True

    if not image_exists_fn(cached.get("image_id", "")):
        return True

    return False


def update_output_hash(cache: dict, output: str, input_hash: str):
    """Record the input hash for a built output."""
    cache[output] = input_hash


def update_image_hash(cache: dict, tag: str, input_hash: str, image_id: str):
    """Record the build state for a docker image."""
    cache[f"docker:{tag}"] = {
        "input_hash": input_hash,
        "image_id": image_id,
    }
