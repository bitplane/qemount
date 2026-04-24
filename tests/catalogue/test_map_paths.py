"""Tests for catalogue.map_paths."""

from pathlib import Path

import pytest

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
    """Multiple files mapping to same path are rejected."""
    files = {
        "docs/fs/ext4.md": {"meta": {}, "content": "", "hash": "abc"},
        "other/ext4.md": {"meta": {"path": "fs/ext4"}, "content": "", "hash": "def"},
    }
    with pytest.raises(ValueError, match="Duplicate catalogue path"):
        map_paths(files)


def test_map_paths_conflict_index_and_file():
    """foo.md and foo/index.md cannot both define logical path foo."""
    files = {
        "foo.md": {"meta": {}, "content": "", "hash": "abc"},
        "foo/index.md": {"meta": {}, "content": "", "hash": "def"},
    }
    with pytest.raises(ValueError, match=r"foo: .*foo\.md.*foo/index\.md"):
        map_paths(files)


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
