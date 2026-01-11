"""Tests for build_requires merging into requires."""

from pathlib import Path

from qemount_build.catalogue import load, resolve_path


DATA_DIR = Path(__file__).parent / "data"


def test_build_requires_merged_into_requires():
    """build_requires items are merged into requires."""
    cat = load(DATA_DIR / "build_requires")
    ctx = {}

    meta = resolve_path("", cat, ctx)

    # Original requires preserved
    assert "existing/dep" in meta["requires"]

    # build_requires merged in
    assert "sources/foo" in meta["requires"]
    assert "sources/bar" in meta["requires"]

    # build_requires still present
    assert "sources/foo" in meta["build_requires"]
    assert "sources/bar" in meta["build_requires"]


def test_build_requires_no_duplicates():
    """build_requires doesn't duplicate existing requires."""
    cat = load(DATA_DIR / "build_requires")
    ctx = {}

    meta = resolve_path("", cat, ctx)

    # Count occurrences - should not have duplicates
    requires_list = list(meta["requires"].keys())
    assert requires_list.count("existing/dep") == 1
