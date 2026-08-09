"""Tests for the cache module."""

import tempfile
from pathlib import Path

from qemount_build.cache import (
    load_cache,
    save_cache,
    hash_file,
    hash_files,
    hash_path_inputs,
    hash_source_inputs,
    strip_ref_prefix,
    is_output_dirty,
    update_output_hash,
)


def test_load_cache_missing():
    """Loading from non-existent file returns empty dict."""
    with tempfile.TemporaryDirectory() as tmp:
        cache = load_cache(Path(tmp))
        assert cache == {"__schema__": 2}


def test_save_and_load_cache():
    """Cache round-trips through save/load."""
    with tempfile.TemporaryDirectory() as tmp:
        build_dir = Path(tmp)
        cache = {"output/foo": "abc123", "output/bar": "def456"}
        save_cache(build_dir, cache)
        loaded = load_cache(build_dir)
        assert loaded == cache


def test_strip_ref_prefix():
    """Known ref prefixes are stripped."""
    assert strip_ref_prefix("docker:builder/base") == "builder/base"
    assert strip_ref_prefix("file:catalogue.json") == "catalogue.json"
    assert strip_ref_prefix("sources/foo.tar.gz") == "sources/foo.tar.gz"


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
        build_dir = Path(tmp)
        (build_dir / "foo").write_text("data")
        cache = {}
        update_output_hash(cache, "foo", "abc123", build_dir)

        assert not is_output_dirty("foo", "abc123", cache, build_dir)


def test_is_output_dirty_modified_output():
    """Output content changes are dirty even when inputs are unchanged."""
    with tempfile.TemporaryDirectory() as tmp:
        build_dir = Path(tmp)
        (build_dir / "foo").write_text("data")
        cache = {}
        update_output_hash(cache, "foo", "abc123", build_dir)

        (build_dir / "foo").write_text("changed")

        assert is_output_dirty("foo", "abc123", cache, build_dir)


def test_directory_output_trusts_input_identity_and_existence(tmp_path):
    output = tmp_path / "sdk"
    output.mkdir()
    (output / "header.h").write_text("original")
    cache = {}
    update_output_hash(cache, "sdk", "inputs", tmp_path)

    assert cache["sdk"]["kind"] == "directory"
    assert not is_output_dirty("sdk", "inputs", cache, tmp_path)

    (output / "header.h").write_text("locally damaged")
    assert not is_output_dirty("sdk", "inputs", cache, tmp_path)


def test_directory_output_is_dirty_when_absent_or_replaced(tmp_path):
    output = tmp_path / "sdk"
    output.mkdir()
    cache = {}
    update_output_hash(cache, "sdk", "inputs", tmp_path)

    output.rmdir()
    assert is_output_dirty("sdk", "inputs", cache, tmp_path)

    output.write_text("not a directory")
    assert is_output_dirty("sdk", "inputs", cache, tmp_path)


def test_is_output_dirty_output_requires_clean():
    """Output-specific requires are included in the clean cache state."""
    with tempfile.TemporaryDirectory() as tmp:
        build_dir = Path(tmp)
        (build_dir / "foo").write_text("data")
        (build_dir / "dep.bin").write_text("dependency")
        cache = {}
        update_output_hash(cache, "foo", "abc123", build_dir, ["dep.bin"])

        assert not is_output_dirty("foo", "abc123", cache, build_dir, ["dep.bin"])


def test_is_output_dirty_output_requires_changed():
    """Changing an output-specific required file dirties the output."""
    with tempfile.TemporaryDirectory() as tmp:
        build_dir = Path(tmp)
        (build_dir / "foo").write_text("data")
        (build_dir / "dep.bin").write_text("dependency")
        cache = {}
        update_output_hash(cache, "foo", "abc123", build_dir, ["dep.bin"])

        (build_dir / "dep.bin").write_text("changed")

        assert is_output_dirty("foo", "abc123", cache, build_dir, ["dep.bin"])


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


def test_hash_files_nonexistent():
    """Hashing non-existent directory returns consistent empty hash."""
    cache = {}
    h1 = hash_files(Path("/nonexistent/path/that/does/not/exist"), cache)
    h2 = hash_files(Path("/another/nonexistent/path"), cache)
    assert h1 == h2  # Both return hash of empty content


def test_source_hash_ignores_transfer_environment():
    first = {
        "urls": {"https://example.test/source.tar": {}},
        "provides": {"sources/source.tar": {}},
        "env": {"BUILD_PLATFORM": "x86_64-linux"},
        "requires": {"docker:builder/downloader": {}},
    }
    second = {
        **first,
        "env": {"BUILD_PLATFORM": "aarch64-linux"},
        "requires": {"docker:builder/new-downloader": {}},
    }
    assert hash_source_inputs(first) == hash_source_inputs(second)


def test_source_hash_changes_with_url():
    first = {
        "urls": {"https://example.test/one.tar": {}},
        "provides": {"sources/source.tar": {}},
    }
    second = {
        "urls": {"https://example.test/two.tar": {}},
        "provides": {"sources/source.tar": {}},
    }
    assert hash_source_inputs(first) != hash_source_inputs(second)


def test_output_cache_survives_build_directory_relocation(tmp_path):
    original = tmp_path / "first" / "build"
    original.mkdir(parents=True)
    (original / "artifact").write_text("content")
    cache = {}
    update_output_hash(cache, "artifact", "inputs", original)

    relocated = tmp_path / "second" / "build"
    relocated.parent.mkdir()
    original.rename(relocated)

    assert not is_output_dirty("artifact", "inputs", cache, relocated)


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


def test_hash_path_inputs_metadata():
    """hash_path_inputs includes resolved metadata consumed through META."""
    with tempfile.TemporaryDirectory() as tmp:
        pkg_dir = Path(tmp) / "pkg"
        build_dir = Path(tmp) / "build"
        pkg_dir.mkdir()
        build_dir.mkdir()

        cache = {}
        h1 = hash_path_inputs(
            "sources/example",
            pkg_dir,
            {"urls": ["https://example.com/one.tar.gz"]},
            {},
            build_dir,
            cache,
        )
        h2 = hash_path_inputs(
            "sources/example",
            pkg_dir,
            {"urls": ["https://example.com/two.tar.gz"]},
            {},
            build_dir,
            cache,
        )

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
