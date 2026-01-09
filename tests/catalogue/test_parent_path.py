"""Tests for catalogue.parent_path."""

import pytest

from qemount_build.catalogue import parent_path


@pytest.mark.parametrize("path,expected", [
    ("format/fs/ext4", "format/fs"),
    ("format/fs", "format"),
    ("format", ""),
    ("", ""),
    ("bin/qemu/linux/6.17", "bin/qemu/linux"),
    ("a/b/c/d/e", "a/b/c/d"),
])
def test_parent_path(path, expected):
    assert parent_path(path) == expected
