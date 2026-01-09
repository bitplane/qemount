"""Tests for catalogue.resolve_inheritance."""

from pathlib import Path

from qemount_build.catalogue import load_docs, map_paths, resolve_inheritance


DATA_DIR = Path(__file__).parent / "data"


def test_root_has_own_meta():
    """Root path has its own metadata."""
    files = load_docs(DATA_DIR / "inheritance")
    paths = map_paths(files)
    resolved = resolve_inheritance(files, paths)

    assert resolved[""]["meta"]["title"] == "Root"
    assert "a" in resolved[""]["meta"]["supports"]


def test_child_inherits_from_root():
    """Child inherits supports from root."""
    files = load_docs(DATA_DIR / "inheritance")
    paths = map_paths(files)
    resolved = resolve_inheritance(files, paths)

    supports = resolved["child"]["meta"]["supports"]
    # Has a and c from root
    assert "a" in supports
    assert "c" in supports
    # Has d from child
    assert "d" in supports
    # b was deleted
    assert "b" not in supports


def test_leaf_inherits_chain():
    """Leaf inherits from child which inherits from root."""
    files = load_docs(DATA_DIR / "inheritance")
    paths = map_paths(files)
    resolved = resolve_inheritance(files, paths)

    meta = resolved["child/leaf"]["meta"]
    # Has own property
    assert meta["extra"] == "value"
    assert meta["title"] == "Leaf"
    # Has inherited supports (a, c, d but not b)
    supports = meta["supports"]
    assert "a" in supports
    assert "c" in supports
    assert "d" in supports
    assert "b" not in supports


def test_sources_preserved():
    """Original sources list is preserved after resolution."""
    files = load_docs(DATA_DIR / "inheritance")
    paths = map_paths(files)
    resolved = resolve_inheritance(files, paths)

    assert "sources" in resolved[""]
    assert "sources" in resolved["child"]
    assert "sources" in resolved["child/leaf"]
