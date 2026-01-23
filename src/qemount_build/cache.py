"""
Build cache for qemount build system.

Tracks input hashes to detect when outputs need rebuilding.
Uses a Merkle tree approach - each path's hash includes its dependency hashes,
so changes propagate up the dependency chain.
"""

import hashlib
import json
from pathlib import Path

from .log import timed


CACHE_FILE = "cache/build_cache.json"


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


def hash_file(path: Path, cache: dict) -> str:
    """
    Hash a file, using cached hash if mtime+size unchanged.

    Returns content hash (md5). Caches by absolute path with mtime+size.
    """
    key = f"file:{path.absolute()}"
    stat = path.stat()
    mtime = stat.st_mtime
    size = stat.st_size

    cached = cache.get(key)
    if cached and cached["mtime"] == mtime and cached["size"] == size:
        return cached["hash"]

    # Hash the file
    h = hashlib.md5()
    h.update(path.read_bytes())
    file_hash = h.hexdigest()

    cache[key] = {"mtime": mtime, "size": size, "hash": file_hash}
    return file_hash


@timed
def hash_files(directory: Path, cache: dict) -> str:
    """Hash all files in a directory recursively."""
    h = hashlib.md5()
    if not directory.exists():
        return h.hexdigest()

    for f in sorted(directory.rglob("*")):
        if f.is_file():
            rel = f.relative_to(directory)
            h.update(str(rel).encode())
            h.update(hash_file(f, cache).encode())

    return h.hexdigest()


@timed
def hash_path_inputs(
    path: str,
    pkg_dir: Path,
    resolved: dict,
    dep_hashes: dict,
    build_dir: Path,
    cache: dict,
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
    h.update(hash_files(context_dir, cache).encode())

    # Hash dependency hashes (Merkle tree) or file contents
    for req in sorted(resolved.get("requires", {}).keys()):
        h.update(req.encode())
        # Strip docker: prefix for dep_hashes lookup (paths don't include prefix)
        dep_key = req[7:] if req.startswith("docker:") else req
        if dep_key in dep_hashes:
            h.update(dep_hashes[dep_key].encode())
        else:
            req_path = build_dir / req
            if req_path.exists():
                h.update(hash_file(req_path, cache).encode())

    # Hash build_requires (mounted during docker build)
    for req in sorted(resolved.get("build_requires", {}).keys()):
        h.update(req.encode())
        req_path = build_dir / req
        if req_path.exists():
            if req_path.is_file():
                h.update(hash_file(req_path, cache).encode())
            else:
                h.update(hash_files(req_path, cache).encode())

    # Hash env vars
    env = resolved.get("env", {})
    if env:
        h.update(json.dumps(sorted(env.items())).encode())

    return h.hexdigest()


def hash_output_inputs(
    base_hash: str,
    output_requires: list[str],
    cache: dict,
    build_dir: Path,
) -> str:
    """Compute input hash for a specific output, including its per-output requires."""
    if not output_requires:
        return base_hash
    h = hashlib.md5()
    h.update(base_hash.encode())
    for req in sorted(output_requires):
        h.update(req.encode())
        req_path = build_dir / req
        if req_path.exists():
            h.update(hash_file(req_path, cache).encode())
    return h.hexdigest()


def is_output_dirty(
    output: str,
    input_hash: str,
    cache: dict,
    build_dir: Path,
    output_requires: list[str] | None = None,
) -> bool:
    """Check if a file output needs rebuilding."""
    if not (build_dir / output).exists():
        return True
    cached = cache.get(output)
    if cached is None:
        return True
    # Include per-output requires in hash
    full_hash = hash_output_inputs(input_hash, output_requires or [], cache, build_dir)
    return cached.get("input_hash") != full_hash


def is_image_dirty(
    tag: str,
    input_hash: str,
    cache: dict,
    image_exists_fn,
    host_arch: str,
) -> bool:
    """
    Check if a docker image needs rebuilding.

    Returns True if input_hash changed or image doesn't exist.
    Cache key includes host_arch to separate per-arch builds.
    """
    cache_key = f"docker:{tag}:{host_arch}"
    cached = cache.get(cache_key)

    if cached is None:
        return True

    if cached.get("input_hash") != input_hash:
        return True

    if not image_exists_fn(cached.get("hash", "")):
        return True

    return False


def update_output_hash(
    cache: dict,
    output: str,
    input_hash: str,
    build_dir: Path,
    output_requires: list[str] | None = None,
):
    """Record hash state for a built file output."""
    path = build_dir / output
    stat = path.stat()
    h = hashlib.md5()
    h.update(path.read_bytes())
    # Include per-output requires in stored hash
    full_hash = hash_output_inputs(input_hash, output_requires or [], cache, build_dir)
    cache[output] = {
        "input_hash": full_hash,
        "hash": h.hexdigest(),
        "mtime": stat.st_mtime,
        "size": stat.st_size,
    }


def update_image_hash(cache: dict, tag: str, input_hash: str, image_id: str, host_arch: str):
    """Record hash state for a docker image."""
    cache[f"docker:{tag}:{host_arch}"] = {
        "input_hash": input_hash,
        "hash": image_id,
    }
