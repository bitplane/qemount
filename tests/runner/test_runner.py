"""Tests for runner.py helpers."""

import io
import sys

import pytest

from qemount_build.cache import save_cache, update_output_hash
from qemount_build.runner import (
    build_log_path,
    get_image_tag,
    get_docker_provides,
    get_file_provides,
    image_needs_no_cache,
    begin_output_transaction,
    finish_output_transaction,
    run_streaming,
    validate_path_provides,
    run_build,
)


def test_build_log_path_mirrors_catalogue_path(tmp_path):
    """Stage logs mirror catalogue paths and distinguish command phases."""
    result = build_log_path(
        tmp_path,
        "bin/qemu/aros/pc-i386/system",
        "run",
    )

    assert result == (tmp_path / "logs/bin/qemu/aros/pc-i386/system.run.log")


def test_run_streaming_tees_output_to_stream_and_log(tmp_path):
    """Command output is visible immediately and retained with its exit status."""
    terminal = io.StringIO()
    log_path = tmp_path / "logs/stage.run.log"

    returncode = run_streaming(
        [
            sys.executable,
            "-c",
            (
                "import sys; "
                "sys.stdout.write('stdout\\n'); sys.stdout.flush(); "
                "sys.stderr.write('stderr\\n'); sys.stderr.flush()"
            ),
        ],
        log_path,
        stream=terminal,
    )

    assert returncode == 0
    assert terminal.getvalue() == "stdout\nstderr\n"
    retained = log_path.read_text()
    assert "stdout\nstderr\n" in retained
    assert "[qemount] exit status: 0\n" in retained


def test_run_streaming_retains_failed_command_without_replaying_it(tmp_path):
    """Failed commands retain their output once and record the non-zero status."""
    terminal = io.StringIO()
    log_path = tmp_path / "logs/stage.image.log"

    returncode = run_streaming(
        [
            sys.executable,
            "-c",
            "import sys; sys.stdout.write('broken'); sys.exit(23)",
        ],
        log_path,
        stream=terminal,
    )

    assert returncode == 23
    assert terminal.getvalue() == "broken\n"
    retained = log_path.read_text()
    assert retained.count("broken") == 1
    assert "[qemount] exit status: 23\n" in retained


def test_get_image_tag_docker():
    """Extracts tag from docker: prefix."""
    resolved = {"runs_on": "docker:builder/disk/alpine"}
    assert get_image_tag(resolved) == "builder/disk/alpine"


def test_get_image_tag_none():
    """Returns None when no runs_on."""
    assert get_image_tag({}) is None


def test_get_image_tag_invalid():
    """Raises on non-docker runs_on."""
    with pytest.raises(ValueError, match="must start with 'docker:'"):
        get_image_tag({"runs_on": "local:something"})


def test_get_docker_provides():
    """Filters and strips docker: provides."""
    provides = ["docker:builder/base", "data/fs/fat32", "docker:builder/disk"]
    result = get_docker_provides(provides)
    assert result == ["builder/base", "builder/disk"]


def test_get_file_provides():
    """Filters out docker: provides."""
    provides = ["docker:builder/base", "data/fs/fat32", "data/fs/ext4"]
    result = get_file_provides(provides)
    assert result == ["data/fs/fat32", "data/fs/ext4"]


def test_image_needs_no_cache_for_force():
    """A forced image build always bypasses Podman's layer cache."""
    assert image_needs_no_cache(True, []) is True


def test_image_needs_no_cache_for_build_requires():
    """Mounted build inputs cannot safely use Podman's layer cache."""
    assert image_needs_no_cache(False, ["sources/source.tar.gz"]) is True


def test_image_allows_cache_without_mounted_inputs():
    """Ordinary image builds retain Podman's layer cache."""
    assert image_needs_no_cache(False, []) is False


def test_validate_path_provides_valid_docker():
    """Docker provides with Dockerfile is valid."""
    result = validate_path_provides(
        "mypath", ["builder/base"], [], has_dockerfile=True, runs_on_tag=None
    )
    assert result is None


def test_validate_path_provides_docker_no_dockerfile():
    """Docker provides without Dockerfile is invalid."""
    result = validate_path_provides(
        "mypath", ["builder/base"], [], has_dockerfile=False, runs_on_tag=None
    )
    assert "provides docker image but has no Dockerfile" in result


def test_validate_path_provides_valid_file_with_dockerfile():
    """File provides with Dockerfile is valid."""
    result = validate_path_provides(
        "mypath", [], ["data/foo"], has_dockerfile=True, runs_on_tag=None
    )
    assert result is None


def test_validate_path_provides_valid_file_with_runs_on():
    """File provides with runs_on is valid."""
    result = validate_path_provides(
        "mypath", [], ["data/foo"], has_dockerfile=False, runs_on_tag="builder/base"
    )
    assert result is None


def test_validate_path_provides_file_no_dockerfile_no_runs_on():
    """File provides without Dockerfile or runs_on is invalid."""
    result = validate_path_provides(
        "mypath", [], ["data/foo"], has_dockerfile=False, runs_on_tag=None
    )
    assert "provides files but has no Dockerfile or runs_on" in result


def test_validate_path_provides_no_provides():
    """No provides is valid."""
    result = validate_path_provides(
        "mypath", [], [], has_dockerfile=False, runs_on_tag=None
    )
    assert result is None


def test_failed_output_transaction_restores_previous_file(tmp_path):
    output = tmp_path / "data/result"
    output.parent.mkdir(parents=True)
    output.write_text("previous")

    backups = begin_output_transaction(tmp_path, ["data/result"])
    output.write_text("partial")
    finish_output_transaction(tmp_path, ["data/result"], backups, False)

    assert output.read_text() == "previous"
    assert not (output.parent / "result.qemount-previous").exists()


def test_successful_output_transaction_discards_previous_file(tmp_path):
    output = tmp_path / "result"
    output.write_text("previous")

    backups = begin_output_transaction(tmp_path, ["result"])
    output.write_text("replacement")
    finish_output_transaction(tmp_path, ["result"], backups, True)

    assert output.read_text() == "replacement"
    assert not (tmp_path / "result.qemount-previous").exists()


def test_new_transaction_recovers_previous_file_after_interruption(tmp_path):
    output = tmp_path / "result"
    output.write_text("previous")
    begin_output_transaction(tmp_path, ["result"])
    output.write_text("partial")

    backups = begin_output_transaction(tmp_path, ["result"])

    assert not output.exists()
    assert backups["result"].read_text() == "previous"
    finish_output_transaction(tmp_path, ["result"], backups, False)
    assert output.read_text() == "previous"


def test_existing_source_is_adopted_without_running_downloader(tmp_path, monkeypatch):
    build_dir = tmp_path / "build"
    pkg_dir = tmp_path / "catalogue"
    output = "sources/source.tar"
    path = build_dir / output
    path.parent.mkdir(parents=True)
    path.write_bytes(b"already downloaded")
    cache = {}
    update_output_hash(cache, output, "legacy-input", build_dir)
    save_cache(build_dir, cache)

    catalogue = {
        "paths": {
            "source": {
                "sources": ["source.md"],
                "meta": {
                    "urls": {"https://example.test/source.tar": {}},
                    "runs_on": "docker:builder/downloader",
                    "provides": {output: {}},
                },
            }
        }
    }

    def unexpected_download(*args, **kwargs):
        raise AssertionError("downloader should not run")

    monkeypatch.setattr("qemount_build.runner.run_container", unexpected_download)
    success = run_build(
        [output],
        catalogue,
        {
            "BUILD_PLATFORM": "x86_64-linux",
            "BUILD_ARCH": "x86_64",
            "BUILD_OS": "linux",
        },
        build_dir,
        pkg_dir,
    )

    assert success
    assert path.read_bytes() == b"already downloaded"
