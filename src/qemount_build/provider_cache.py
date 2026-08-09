"""Automatic cache paths for catalogue provider instances."""

import hashlib
import re
from pathlib import Path


CONTAINER_CACHE_ROOT = Path("/host/build/cache/stages")


def provider_cache_name(instance_id: str) -> str:
    """Return a readable, collision-resistant, tool-safe directory name."""
    if not instance_id:
        return "_root"
    slug = re.sub(r"[^A-Za-z0-9._-]+", "-", instance_id).strip("-")
    slug = slug[:80] or "provider"
    digest = hashlib.sha256(instance_id.encode()).hexdigest()[:24]
    return f"{slug}--{digest}"


def provider_cache_relative(build_platform: str, instance_id: str) -> Path:
    """Return a provider cache path relative to build/cache."""
    return Path("stages") / build_platform / provider_cache_name(instance_id)


def provider_cache_container(build_platform: str, instance_id: str) -> str:
    """Return the provider cache path visible inside build containers."""
    return str(
        CONTAINER_CACHE_ROOT / build_platform / provider_cache_name(instance_id)
    )
