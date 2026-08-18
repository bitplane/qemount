"""Tests for runner.py helpers."""

import io
import re
import sys
from pathlib import Path
from types import SimpleNamespace

import pytest

from mountin.cache import save_cache, update_output_hash
from mountin.runner import (
    begin_output_transaction,
    build_image,
    build_log_path,
    dockerfile_build_args,
    finish_output_transaction,
    get_docker_provides,
    get_file_provides,
    get_image_tag,
    image_needs_no_cache,
    local_image_tag,
    podman_runtime_args,
    prepare_provider_cache,
    provider_environment,
    run_build,
    run_container,
    run_streaming,
    validate_path_provides,
)


def test_provider_environment_exposes_execution_context_only():
    context = {
        "BUILD_PLATFORM": "x86_64-linux",
        "TARGET_PLATFORM": "x86_64-linux",
        "BUILD_JOBS": "12",
        "RELEASE_REF": "abcdef",
        "SOURCE_KIND": "checkout",
        "MOUNTIN_CACHE_DIR": "/cache",
    }

    meta = {
        "execution_env": {"BUILD_JOBS": "1"},
        "env": {"CUSTOM": "yes"},
    }

    assert provider_environment(context, meta) == {
        "BUILD_PLATFORM": "x86_64-linux",
        "TARGET_PLATFORM": "x86_64-linux",
        "BUILD_JOBS": "1",
        "MOUNTIN_CACHE_DIR": "/cache",
        "CUSTOM": "yes",
    }


def test_local_image_tag_normalizes_invalid_repository_characters_without_collisions():
    normalized = local_image_tag(
        "guest/haiku/r1-beta6-hrev59919+1", "x86_64-haiku"
    )

    assert re.fullmatch(r"localhost/[a-z0-9._/-]+:[a-z0-9_.-]+", normalized)
    assert normalized != local_image_tag(
        "guest/haiku/r1-beta6-hrev59919-1", "x86_64-haiku"
    )

def test_build_image_uses_stable_ownership_label(tmp_path, monkeypatch):
    context = tmp_path / "context"
    context.mkdir()
    (context / "Dockerfile").write_text("FROM scratch\n")
    commands = []

    def run(command, *_args, **_kwargs):
        commands.append(command)
        return 0

    monkeypatch.setattr("mountin.runner.run_streaming", run)
    monkeypatch.setattr("mountin.runner.get_image_id", lambda _tag: "sha256:image")

    assert (
        build_image(
            "example",
            context,
            "localhost/example",
            {"BUILD_PLATFORM": "x86_64-linux"},
            [],
            tmp_path,
        )
        == "sha256:image"
    )
    assert ["--label", "org.mountin.managed=true"] == commands[0][2:4]
    assert not any("input-hash" in argument for argument in commands[0])


def test_dockerfile_build_args_reads_global_and_stage_arguments(tmp_path):
    dockerfile = tmp_path / "Dockerfile"
    dockerfile.write_text("ARG BASE=example\nFROM ${BASE}\n  ARG BUILD_JOBS\nARG MOUNTIN_CACHE_DIR=/cache\nRUN true\n")

    assert dockerfile_build_args(dockerfile) == {
        "BASE",
        "BUILD_JOBS",
        "MOUNTIN_CACHE_DIR",
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
        "guest/aros/2026-07-30",
        "run",
    )

    assert result == (tmp_path / "logs/guest/aros/2026-07-30.run.log")


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
    assert "[mountin] exit status: 0\n" in retained


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
    assert "[mountin] exit status: 23\n" in retained


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
    monkeypatch.setattr("mountin.runner.subprocess.Popen", lambda *args, **kwargs: process)
    log_path = tmp_path / "stage.run.log"

    with pytest.raises(KeyboardInterrupt):
        run_streaming(["ignored"], log_path, stream=io.StringIO())

    assert process.terminated
    assert process.waited
    assert "[mountin] interrupted\n" in log_path.read_text()


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

    monkeypatch.setattr("mountin.runner.run_streaming", interrupt)
    monkeypatch.setattr("mountin.runner.subprocess.run", record_run)
    monkeypatch.setattr("mountin.runner.podman_runtime_args", lambda: [])

    with pytest.raises(KeyboardInterrupt):
        run_container(
            "stage",
            "image",
            tmp_path,
            {"BUILD_PLATFORM": "x86_64-linux"},
            ["output"],
        )

    assert removed == [["podman", "rm", "--force", "test-container-id"]]
    mounts = [commands[0][index + 1] for index, argument in enumerate(commands[0]) if argument == "-v"]
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
    result = validate_path_provides("mypath", ["builder/base"], [], has_dockerfile=True, runs_on_tag=None)
    assert result is None


def test_validate_path_provides_docker_no_dockerfile():
    """Docker provides without Dockerfile is invalid."""
    result = validate_path_provides("mypath", ["builder/base"], [], has_dockerfile=False, runs_on_tag=None)
    assert "provides docker image but has no Dockerfile" in result


def test_validate_path_provides_valid_file_with_dockerfile():
    """File provides with Dockerfile is valid."""
    result = validate_path_provides("mypath", [], ["data/foo"], has_dockerfile=True, runs_on_tag=None)
    assert result is None


def test_validate_path_provides_valid_file_with_runs_on():
    """File provides with runs_on is valid."""
    result = validate_path_provides("mypath", [], ["data/foo"], has_dockerfile=False, runs_on_tag="builder/base")
    assert result is None


def test_validate_path_provides_file_no_dockerfile_no_runs_on():
    """File provides without Dockerfile or runs_on is invalid."""
    result = validate_path_provides("mypath", [], ["data/foo"], has_dockerfile=False, runs_on_tag=None)
    assert "provides files but has no Dockerfile or runs_on" in result


def test_validate_path_provides_no_provides():
    """No provides is valid."""
    result = validate_path_provides("mypath", [], [], has_dockerfile=False, runs_on_tag=None)
    assert result is None


def test_failed_output_transaction_restores_previous_file(tmp_path):
    output = tmp_path / "data/result"
    output.parent.mkdir(parents=True)
    output.write_text("previous")

    backups = begin_output_transaction(tmp_path, ["data/result"])
    output.write_text("partial")
    finish_output_transaction(tmp_path, ["data/result"], backups, False)

    assert output.read_text() == "previous"
    assert not (output.parent / "result.mountin-previous").exists()


def test_successful_output_transaction_discards_previous_file(tmp_path):
    output = tmp_path / "result"
    output.write_text("previous")

    backups = begin_output_transaction(tmp_path, ["result"])
    output.write_text("replacement")
    finish_output_transaction(tmp_path, ["result"], backups, True)

    assert output.read_text() == "replacement"
    assert not (tmp_path / "result.mountin-previous").exists()


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
    assert not (tmp_path / "sdk.mountin-previous").exists()


def test_successful_output_transaction_discards_previous_directory(tmp_path):
    output = tmp_path / "sdk"
    output.mkdir()
    (output / "previous.h").write_text("previous")

    backups = begin_output_transaction(tmp_path, ["sdk"])
    output.mkdir()
    (output / "replacement.h").write_text("replacement")
    finish_output_transaction(tmp_path, ["sdk"], backups, True)

    assert (output / "replacement.h").read_text() == "replacement"
    assert not (tmp_path / "sdk.mountin-previous").exists()


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

    assert prepare_provider_cache(tmp_path, "x86_64-linux", "stage", "one") == cache
    assert (cache / "objects").read_text() == "reusable"

    prepare_provider_cache(tmp_path, "x86_64-linux", "stage", "two")
    assert not (cache / "objects").exists()
    assert (cache.parent / ".mountin-input").read_text() == "two\n"


def test_provider_cache_metadata_is_outside_the_builder_workspace(tmp_path):
    cache = prepare_provider_cache(tmp_path, "x86_64-linux", "stage", "one")
    marker = cache.parent / ".mountin-input"

    for child in cache.iterdir():
        if child.is_dir():
            child.rmdir()
        else:
            child.unlink()

    assert marker.read_text() == "one\n"
    assert prepare_provider_cache(tmp_path, "x86_64-linux", "stage", "one") == cache
