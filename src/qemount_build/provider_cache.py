"""Automatic cache paths for catalogue provider instances."""

from pathlib import Path
from urllib.parse import quote


CONTAINER_CACHE_ROOT = Path("/host/build/cache/stages")


def provider_cache_name(instance_id: str) -> str:
    """Encode a provider instance as one filesystem-safe directory name."""
    return quote(instance_id, safe="-._") or "_root"


def provider_cache_relative(build_platform: str, instance_id: str) -> Path:
    """Return a provider cache path relative to build/cache."""
    return Path("stages") / build_platform / provider_cache_name(instance_id)


def provider_cache_container(build_platform: str, instance_id: str) -> str:
    """Return the provider cache path visible inside build containers."""
    return str(
        CONTAINER_CACHE_ROOT / build_platform / provider_cache_name(instance_id)
    )
