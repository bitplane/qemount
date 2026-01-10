"""Tests for catalogue.resolve_path."""

from pathlib import Path

import pytest

from qemount_build.catalogue import load, resolve_path


DATA_DIR = Path(__file__).parent / "data"


def test_resolve_path_root():
    """Root path resolves env from external context."""
    cat = load(DATA_DIR / "vars")
    ctx = {"HOST_ARCH": "x86_64", "ARCH": "x86_64"}

    meta = resolve_path("", cat, ctx)

    assert meta["env"]["HOST_ARCH"] == "x86_64"
    assert meta["env"]["ARCH"] == "x86_64"


def test_resolve_path_child():
    """Child resolves BUILDER using inherited HOST_ARCH."""
    cat = load(DATA_DIR / "vars")
    ctx = {"HOST_ARCH": "x86_64", "ARCH": "aarch64"}

    meta = resolve_path("child", cat, ctx)

    assert meta["env"]["BUILDER"] == "builder/x86_64"
    assert "docker:builder/x86_64" in meta["requires"]
    assert "output/aarch64/thing" in meta["provides"]


def test_resolve_path_leaf():
    """Leaf resolves using full inherited context."""
    cat = load(DATA_DIR / "vars")
    ctx = {"HOST_ARCH": "x86_64", "ARCH": "aarch64"}

    meta = resolve_path("child/leaf", cat, ctx)

    assert "docker:builder/x86_64" in meta["requires"]
    assert "source.tar" in meta["requires"]
    assert "output/aarch64/leaf" in meta["provides"]


def test_resolve_path_different_arch():
    """Same path resolves differently with different context."""
    cat = load(DATA_DIR / "vars")

    meta_x86 = resolve_path("child/leaf", cat, {"HOST_ARCH": "x86_64", "ARCH": "x86_64"})
    meta_arm = resolve_path("child/leaf", cat, {"HOST_ARCH": "aarch64", "ARCH": "aarch64"})

    assert "output/x86_64/leaf" in meta_x86["provides"]
    assert "output/aarch64/leaf" in meta_arm["provides"]


def test_resolve_path_not_found():
    """Missing path raises KeyError."""
    cat = load(DATA_DIR / "vars")

    with pytest.raises(KeyError):
        resolve_path("nonexistent", cat, {})
