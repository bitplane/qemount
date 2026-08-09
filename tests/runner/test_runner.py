"""Tests for runner.py helpers."""

import io
import sys
from pathlib import Path
from types import SimpleNamespace

import pytest

from qemount_build.cache import save_cache, update_output_hash
from qemount_build.runner import (
    build_log_path,
    dockerfile_build_args,
    get_image_tag,
    get_docker_provides,
    get_file_provides,
    image_needs_no_cache,
    podman_runtime_args,
    prepare_provider_cache,
    begin_output_transaction,
    run_container,
    finish_output_transaction,
    run_streaming,
    validate_path_provides,
    run_build,
)


def test_dockerfile_build_args_reads_global_and_stage_arguments(tmp_path):
    dockerfile = tmp_path / "Dockerfile"
    dockerfile.write_text(
        "ARG BASE=example\n"
        "FROM ${BASE}\n"
        "  ARG JOBS\n"
        "ARG QEMOUNT_CACHE_DIR=/cache\n"
        "RUN true\n"
    )

    assert dockerfile_build_args(dockerfile) == {
        "BASE",
        "JOBS",
        "QEMOUNT_CACHE_DIR",
    }


def test_podman_runtime_args_omit_missing_kvm(tmp_path):
    """Hosts without KVM retain the ordinary rootless container path."""
    assert podman_runtime_args(tmp_path / "missing-kvm") == []


def test_podman_runtime_args_expose_accessible_kvm(tmp_path):
    """An accessible KVM device is passed through with supplementary groups."""
    kvm = tmp_path / "kvm"
    kvm.touch(mode=0o600)

    assert podman_runtime_args(kvm) == [
        "--device",
        str(kvm),
        "--group-add",
        "keep-groups",
    ]


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


def test_run_streaming_stops_child_when_interrupted(tmp_path, monkeypatch):
    """An interrupted logger terminates and reaps its child process."""

    class InterruptedOutput:
        def __iter__(self):
            return self

        def __next__(self):
            raise KeyboardInterrupt

    class Process:
        stdout = InterruptedOutput()
        returncode = None
        terminated = False
        waited = False

        def poll(self):
            return self.returncode

        def terminate(self):
            self.terminated = True
            self.returncode = -15

        def wait(self, timeout=None):
            self.waited = True
            return self.returncode

    process = Process()
    monkeypatch.setattr(
        "qemount_build.runner.subprocess.Popen", lambda *args, **kwargs: process
    )
    log_path = tmp_path / "stage.run.log"

    with pytest.raises(KeyboardInterrupt):
        run_streaming(["ignored"], log_path, stream=io.StringIO())

    assert process.terminated
    assert process.waited
    assert "[qemount] interrupted\n" in log_path.read_text()


def test_run_container_removes_container_when_interrupted(tmp_path, monkeypatch):
    """Ctrl-C force-removes the exact container recorded by Podman."""
    removed = []
    commands = []

    def interrupt(cmd, log_path):
        commands.append(cmd)
        cid_path = Path(cmd[cmd.index("--cidfile") + 1])
        cid_path.write_text("test-container-id\n")
        raise KeyboardInterrupt

    def record_run(cmd, **kwargs):
        removed.append(cmd)
        return SimpleNamespace(returncode=0)

    monkeypatch.setattr("qemount_build.runner.run_streaming", interrupt)
    monkeypatch.setattr("qemount_build.runner.subprocess.run", record_run)
    monkeypatch.setattr("qemount_build.runner.podman_runtime_args", lambda: [])

    with pytest.raises(KeyboardInterrupt):
        run_container(
            "stage",
            "image",
            tmp_path,
            {"BUILD_PLATFORM": "x86_64-linux"},
            ["output"],
        )

    assert removed == [["podman", "rm", "--force", "test-container-id"]]
    mounts = [
        commands[0][index + 1]
        for index, argument in enumerate(commands[0])
        if argument == "-v"
    ]
    assert any(mount.endswith(":/cache") for mount in mounts)
    assert not list((tmp_path / "cache/containers").iterdir())


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


def test_failed_output_transaction_restores_previous_directory(tmp_path):
    output = tmp_path / "sdk"
    output.mkdir()
    (output / "previous.h").write_text("previous")

    backups = begin_output_transaction(tmp_path, ["sdk"])
    output.mkdir()
    (output / "partial.h").write_text("partial")
    finish_output_transaction(tmp_path, ["sdk"], backups, False)

    assert (output / "previous.h").read_text() == "previous"
    assert not (output / "partial.h").exists()
    assert not (tmp_path / "sdk.qemount-previous").exists()


def test_successful_output_transaction_discards_previous_directory(tmp_path):
    output = tmp_path / "sdk"
    output.mkdir()
    (output / "previous.h").write_text("previous")

    backups = begin_output_transaction(tmp_path, ["sdk"])
    output.mkdir()
    (output / "replacement.h").write_text("replacement")
    finish_output_transaction(tmp_path, ["sdk"], backups, True)

    assert (output / "replacement.h").read_text() == "replacement"
    assert not (tmp_path / "sdk.qemount-previous").exists()


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


def test_provider_cache_is_reused_only_for_identical_inputs(tmp_path):
    cache = prepare_provider_cache(tmp_path, "x86_64-linux", "stage", "one")
    (cache / "objects").write_text("reusable")

    assert prepare_provider_cache(
        tmp_path, "x86_64-linux", "stage", "one"
    ) == cache
    assert (cache / "objects").read_text() == "reusable"

    prepare_provider_cache(tmp_path, "x86_64-linux", "stage", "two")
    assert not (cache / "objects").exists()
    assert (cache.parent / ".qemount-input").read_text() == "two\n"


def test_provider_cache_metadata_is_outside_the_builder_workspace(tmp_path):
    cache = prepare_provider_cache(tmp_path, "x86_64-linux", "stage", "one")
    marker = cache.parent / ".qemount-input"

    for child in cache.iterdir():
        if child.is_dir():
            child.rmdir()
        else:
            child.unlink()

    assert marker.read_text() == "one\n"
    assert prepare_provider_cache(
        tmp_path, "x86_64-linux", "stage", "one"
    ) == cache
