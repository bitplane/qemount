"""Tests for the cache module."""

import tempfile
from pathlib import Path

from qemount_build.cache import (
    load_cache,
    save_cache,
    hash_file,
    hash_files,
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
        cache = {}
        h1 = hash_files(Path(tmp), cache)
        h2 = hash_files(Path(tmp), cache)
        assert h1 == h2


def test_hash_files_content():
    """Hashing includes file content."""
    with tempfile.TemporaryDirectory() as tmp:
        d = Path(tmp)
        cache = {}
        (d / "a.txt").write_text("hello")
        h1 = hash_files(d, cache)

        (d / "a.txt").write_text("world")
        cache.clear()  # Clear cache to force rehash
        h2 = hash_files(d, cache)

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

        cache = {}
        assert hash_files(d1, cache) != hash_files(d2, cache)


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
        cache = {"foo": {"input_hash": "old_hash", "hash": "abc", "mtime": 0, "size": 4}}
        assert is_output_dirty("foo", "new_hash", cache, Path(tmp))


def test_is_output_dirty_clean():
    """Output with matching hash is clean."""
    with tempfile.TemporaryDirectory() as tmp:
        (Path(tmp) / "foo").write_text("data")
        cache = {"foo": {"input_hash": "abc123", "hash": "xyz", "mtime": 0, "size": 4}}
        assert not is_output_dirty("foo", "abc123", cache, Path(tmp))


def test_is_image_dirty_no_cache():
    """Image with no cache is dirty."""
    assert is_image_dirty("my/image", "abc", {}, lambda x: True, "x86_64")


def test_is_image_dirty_hash_changed():
    """Image with changed input_hash is dirty."""
    cache = {
        "docker:my/image:x86_64": {
            "input_hash": "old_hash",
            "hash": "sha256:abc",
        }
    }
    assert is_image_dirty("my/image", "new_hash", cache, lambda x: True, "x86_64")


def test_is_image_dirty_image_missing():
    """Image that doesn't exist is dirty."""
    cache = {
        "docker:my/image:x86_64": {
            "input_hash": "abc",
            "hash": "sha256:abc",
        }
    }
    assert is_image_dirty("my/image", "abc", cache, lambda x: False, "x86_64")


def test_is_image_dirty_clean():
    """Image with matching hash and existing is clean."""
    cache = {
        "docker:my/image:x86_64": {
            "input_hash": "abc",
            "hash": "sha256:abc",
        }
    }
    assert not is_image_dirty("my/image", "abc", cache, lambda x: True, "x86_64")


def test_update_output_hash():
    """update_output_hash stores hash state in cache."""
    with tempfile.TemporaryDirectory() as tmp:
        build_dir = Path(tmp)
        (build_dir / "foo").mkdir()
        (build_dir / "foo/bar").write_text("content")

        cache = {}
        update_output_hash(cache, "foo/bar", "input123", build_dir)

        entry = cache["foo/bar"]
        assert entry["input_hash"] == "input123"
        assert "hash" in entry
        assert "mtime" in entry
        assert "size" in entry


def test_update_image_hash():
    """update_image_hash stores build state in cache."""
    cache = {}
    update_image_hash(cache, "my/image", "input_hash", "sha256:abc", "x86_64")
    assert cache["docker:my/image:x86_64"] == {
        "input_hash": "input_hash",
        "hash": "sha256:abc",
    }


def test_hash_files_nonexistent():
    """Hashing non-existent directory returns consistent empty hash."""
    cache = {}
    h1 = hash_files(Path("/nonexistent/path/that/does/not/exist"), cache)
    h2 = hash_files(Path("/another/nonexistent/path"), cache)
    assert h1 == h2  # Both return hash of empty content


def test_hash_path_inputs_context():
    """hash_path_inputs includes context dir files."""
    with tempfile.TemporaryDirectory() as tmp:
        pkg_dir = Path(tmp) / "pkg"
        build_dir = Path(tmp) / "build"
        pkg_dir.mkdir()
        build_dir.mkdir()

        (pkg_dir / "mypath").mkdir()
        (pkg_dir / "mypath/Dockerfile").write_text("FROM alpine")

        resolved = {"env": {"FOO": "bar"}}
        dep_hashes = {}
        cache = {}

        h1 = hash_path_inputs("mypath", pkg_dir, resolved, dep_hashes, build_dir, cache)

        (pkg_dir / "mypath/Dockerfile").write_text("FROM debian")
        cache.clear()
        h2 = hash_path_inputs("mypath", pkg_dir, resolved, dep_hashes, build_dir, cache)

        assert h1 != h2


def test_hash_path_inputs_env():
    """hash_path_inputs includes env vars."""
    with tempfile.TemporaryDirectory() as tmp:
        pkg_dir = Path(tmp) / "pkg"
        build_dir = Path(tmp) / "build"
        pkg_dir.mkdir()
        build_dir.mkdir()
        (pkg_dir / "mypath").mkdir()

        cache = {}
        h1 = hash_path_inputs("mypath", pkg_dir, {"env": {"A": "1"}}, {}, build_dir, cache)
        h2 = hash_path_inputs("mypath", pkg_dir, {"env": {"A": "2"}}, {}, build_dir, cache)

        assert h1 != h2


def test_hash_path_inputs_requires():
    """hash_path_inputs includes dependency hashes."""
    with tempfile.TemporaryDirectory() as tmp:
        pkg_dir = Path(tmp) / "pkg"
        build_dir = Path(tmp) / "build"
        pkg_dir.mkdir()
        build_dir.mkdir()
        (pkg_dir / "mypath").mkdir()

        resolved = {"requires": {"dep1": {}}}
        cache = {}
        h1 = hash_path_inputs("mypath", pkg_dir, resolved, {"dep1": "hash_a"}, build_dir, cache)
        h2 = hash_path_inputs("mypath", pkg_dir, resolved, {"dep1": "hash_b"}, build_dir, cache)

        assert h1 != h2


def test_hash_path_inputs_file_dep():
    """hash_path_inputs includes file deps from build_dir."""
    with tempfile.TemporaryDirectory() as tmp:
        pkg_dir = Path(tmp) / "pkg"
        build_dir = Path(tmp) / "build"
        pkg_dir.mkdir()
        build_dir.mkdir()
        (pkg_dir / "mypath").mkdir()
        (build_dir / "catalogue.json").write_text('{"version": 1}')

        resolved = {"requires": {"catalogue.json": {}}}
        cache = {}
        h1 = hash_path_inputs("mypath", pkg_dir, resolved, {}, build_dir, cache)

        (build_dir / "catalogue.json").write_text('{"version": 2}')
        cache.clear()
        h2 = hash_path_inputs("mypath", pkg_dir, resolved, {}, build_dir, cache)

        assert h1 != h2


def test_hash_file_cache_hit():
    """hash_file uses cached hash when mtime and size unchanged."""
    with tempfile.TemporaryDirectory() as tmp:
        f = Path(tmp) / "test.txt"
        f.write_text("content")

        cache = {}
        h1 = hash_file(f, cache)

        # Cache should have entry
        assert len(cache) == 1

        # Second call should use cache (same hash returned)
        h2 = hash_file(f, cache)
        assert h1 == h2


def test_hash_path_inputs_build_requires_file():
    """hash_path_inputs includes build_requires files."""
    with tempfile.TemporaryDirectory() as tmp:
        pkg_dir = Path(tmp) / "pkg"
        build_dir = Path(tmp) / "build"
        pkg_dir.mkdir()
        build_dir.mkdir()
        (pkg_dir / "mypath").mkdir()
        (build_dir / "data.bin").write_bytes(b"binary data")

        resolved = {"build_requires": {"data.bin": {}}}
        cache = {}
        h1 = hash_path_inputs("mypath", pkg_dir, resolved, {}, build_dir, cache)

        (build_dir / "data.bin").write_bytes(b"different")
        cache.clear()
        h2 = hash_path_inputs("mypath", pkg_dir, resolved, {}, build_dir, cache)

        assert h1 != h2


def test_hash_path_inputs_build_requires_dir():
    """hash_path_inputs includes build_requires directories."""
    with tempfile.TemporaryDirectory() as tmp:
        pkg_dir = Path(tmp) / "pkg"
        build_dir = Path(tmp) / "build"
        pkg_dir.mkdir()
        build_dir.mkdir()
        (pkg_dir / "mypath").mkdir()
        (build_dir / "subdir").mkdir()
        (build_dir / "subdir/file.txt").write_text("hello")

        resolved = {"build_requires": {"subdir": {}}}
        cache = {}
        h1 = hash_path_inputs("mypath", pkg_dir, resolved, {}, build_dir, cache)

        (build_dir / "subdir/file.txt").write_text("world")
        cache.clear()
        h2 = hash_path_inputs("mypath", pkg_dir, resolved, {}, build_dir, cache)

        assert h1 != h2
