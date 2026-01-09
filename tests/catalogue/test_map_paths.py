"""Tests for catalogue.map_paths."""

from pathlib import Path

from qemount_build.catalogue import map_paths, load_docs


DATA_DIR = Path(__file__).parent / "data"


def test_map_paths_basic():
    """map_paths converts file paths to logical paths."""
    files = {
        "docs/fs/ext4.md": {"meta": {}, "content": "", "hash": "abc"},
        "docs/fs/index.md": {"meta": {}, "content": "", "hash": "def"},
    }
    paths = map_paths(files)
    assert "fs/ext4" in paths
    assert "fs" in paths


def test_map_paths_sources():
    """Each path has sources list with contributing file paths."""
    files = {
        "docs/fs/ext4.md": {"meta": {}, "content": "", "hash": "abc"},
    }
    paths = map_paths(files)
    assert paths["fs/ext4"]["sources"] == ["docs/fs/ext4.md"]


def test_map_paths_conflict():
    """Multiple files mapping to same path are collected."""
    files = {
        "docs/fs/ext4.md": {"meta": {}, "content": "", "hash": "abc"},
        "other/ext4.md": {"meta": {"path": "fs/ext4"}, "content": "", "hash": "def"},
    }
    paths = map_paths(files)
    assert len(paths["fs/ext4"]["sources"]) == 2
    assert "docs/fs/ext4.md" in paths["fs/ext4"]["sources"]
    assert "other/ext4.md" in paths["fs/ext4"]["sources"]


def test_map_paths_with_fixture():
    """map_paths works with load_docs output."""
    files = load_docs(DATA_DIR / "simple")
    paths = map_paths(files)
    # index.md -> ""
    assert "" in paths
    assert "index.md" in paths[""]["sources"]
    # nested/README.md -> "nested"
    assert "nested" in paths
    assert "nested/README.md" in paths["nested"]["sources"]
