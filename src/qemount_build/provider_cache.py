"""Automatic cache paths for catalogue provider instances."""

import hashlib
import re
from pathlib import Path


CONTAINER_CACHE_DIR = "/cache"
PROVIDER_CACHE_VERSION = 2


def provider_cache_name(instance_id: str) -> str:
    """Return a readable, collision-resistant, tool-safe directory name."""
    if not instance_id:
        return "_root"
    slug = re.sub(r"[^A-Za-z0-9._-]+", "-", instance_id).strip("-")
    slug = slug[:80] or "provider"
    identity = f"{PROVIDER_CACHE_VERSION}\0{instance_id}".encode()
    digest = hashlib.sha256(identity).hexdigest()[:24]
    return f"{slug}--{digest}"


def provider_cache_relative(build_platform: str, instance_id: str) -> Path:
    """Return a provider cache path relative to build/cache."""
    return Path("stages") / build_platform / provider_cache_name(instance_id)


def provider_cache_container() -> str:
    """Return the canonical provider cache mount inside build containers."""
    return CONTAINER_CACHE_DIR
