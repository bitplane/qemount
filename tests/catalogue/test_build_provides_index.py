"""Tests for catalogue.build_provides_index."""

from pathlib import Path

import pytest

from qemount_build.catalogue import load, build_provides_index


DATA_DIR = Path(__file__).parent / "data"


def test_build_provides_index_simple():
    """Index maps outputs to paths."""
    cat = load(DATA_DIR / "vars")
    ctx = {"HOST_ARCH": "x86_64", "ARCH": "x86_64"}

    index = build_provides_index(cat, ctx)

    assert index["output/x86_64/thing"] == "child"
    assert index["output/x86_64/leaf"] == "child/leaf"


def test_build_provides_index_different_arch():
    """Index changes with context."""
    cat = load(DATA_DIR / "vars")

    index_x86 = build_provides_index(cat, {"HOST_ARCH": "x86_64", "ARCH": "x86_64"})
    index_arm = build_provides_index(cat, {"HOST_ARCH": "aarch64", "ARCH": "aarch64"})

    assert "output/x86_64/thing" in index_x86
    assert "output/aarch64/thing" in index_arm
    assert "output/x86_64/thing" not in index_arm
