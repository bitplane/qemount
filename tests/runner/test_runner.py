"""Tests for runner.py helpers."""

import pytest

from qemount_build.runner import (
    get_image_tag,
    get_docker_provides,
    get_file_provides,
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
