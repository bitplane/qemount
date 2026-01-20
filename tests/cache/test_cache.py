"""Tests for the cache module."""

import tempfile
from pathlib import Path

from qemount_build.cache import (
    load_cache,
    save_cache,
    hash_files,
    hash_build_requires,
    hash_path_inputs,
    is_output_dirty,
    is_image_dirty,
    update_output_hash,
    update_image_hash,
)


def test_load_cache_missing():
    """Loading from non-existent file returns empty dict."""
    with tempfile.TemporaryDirectory() as tmp:
        cache = load_cache(Path(tmp))
        assert cache == {}


def test_save_and_load_cache():
    """Cache round-trips through save/load."""
    with tempfile.TemporaryDirectory() as tmp:
        build_dir = Path(tmp)
        cache = {"output/foo": "abc123", "output/bar": "def456"}
        save_cache(build_dir, cache)
        loaded = load_cache(build_dir)
        assert loaded == cache


def test_hash_files_empty_dir():
    """Hashing empty directory returns consistent hash."""
    with tempfile.TemporaryDirectory() as tmp:
        h1 = hash_files(Path(tmp))
        h2 = hash_files(Path(tmp))
        assert h1 == h2


def test_hash_files_content():
    """Hashing includes file content."""
    with tempfile.TemporaryDirectory() as tmp:
        d = Path(tmp)
        (d / "a.txt").write_text("hello")
        h1 = hash_files(d)

        (d / "a.txt").write_text("world")
        h2 = hash_files(d)

        assert h1 != h2


def test_hash_files_includes_name():
    """Hashing includes file names."""
    with tempfile.TemporaryDirectory() as tmp:
        d1 = Path(tmp) / "d1"
        d2 = Path(tmp) / "d2"
        d1.mkdir()
        d2.mkdir()

        (d1 / "a.txt").write_text("hello")
        (d2 / "b.txt").write_text("hello")

        assert hash_files(d1) != hash_files(d2)


def test_is_output_dirty_missing():
    """Missing output is dirty."""
    with tempfile.TemporaryDirectory() as tmp:
        assert is_output_dirty("foo", "abc", {}, Path(tmp))


def test_is_output_dirty_no_cache():
    """Output with no cached hash is dirty."""
    with tempfile.TemporaryDirectory() as tmp:
        (Path(tmp) / "foo").write_text("data")
        assert is_output_dirty("foo", "abc", {}, Path(tmp))


def test_is_output_dirty_hash_mismatch():
    """Output with different hash is dirty."""
    with tempfile.TemporaryDirectory() as tmp:
        (Path(tmp) / "foo").write_text("data")
        cache = {"foo": "old_hash"}
        assert is_output_dirty("foo", "new_hash", cache, Path(tmp))


def test_is_output_dirty_clean():
    """Output with matching hash is clean."""
    with tempfile.TemporaryDirectory() as tmp:
        (Path(tmp) / "foo").write_text("data")
        cache = {"foo": "abc123"}
        assert not is_output_dirty("foo", "abc123", cache, Path(tmp))


def test_is_image_dirty_no_cache():
    """Image with no cache is dirty."""
    assert is_image_dirty("my/image", "abc", {}, lambda x: True)


def test_is_image_dirty_hash_changed():
    """Image with changed build_requires is dirty."""
    cache = {
        "docker:my/image": {
            "build_requires_hash": "old_hash",
            "image_id": "sha256:abc",
        }
    }
    assert is_image_dirty("my/image", "new_hash", cache, lambda x: True)


def test_is_image_dirty_image_missing():
    """Image that doesn't exist is dirty."""
    cache = {
        "docker:my/image": {
            "build_requires_hash": "abc",
            "image_id": "sha256:abc",
        }
    }
    assert is_image_dirty("my/image", "abc", cache, lambda x: False)


def test_is_image_dirty_clean():
    """Image with matching hash and existing is clean."""
    cache = {
        "docker:my/image": {
            "build_requires_hash": "abc",
            "image_id": "sha256:abc",
        }
    }
    assert not is_image_dirty("my/image", "abc", cache, lambda x: True)


def test_update_output_hash():
    """update_output_hash stores hash in cache."""
    cache = {}
    update_output_hash(cache, "foo/bar", "hash123")
    assert cache["foo/bar"] == "hash123"


def test_update_image_hash():
    """update_image_hash stores build state in cache."""
    cache = {}
    update_image_hash(cache, "my/image", "br_hash", "sha256:abc")
    assert cache["docker:my/image"] == {
        "build_requires_hash": "br_hash",
        "image_id": "sha256:abc",
    }
