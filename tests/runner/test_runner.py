"""Tests for runner.py helpers."""

import pytest

from qemount_build.runner import (
    get_image_tag,
    get_docker_provides,
    get_file_provides,
    validate_path_provides,
)


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
