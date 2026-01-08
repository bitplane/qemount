"""Tests for catalogue.doc_path."""

import pytest

from qemount_build.catalogue import doc_path


@pytest.mark.parametrize("file_path,meta,expected", [
    # docs/ prefix stripped
    ("docs/fs/ext4.md", {}, "fs/ext4"),
    ("docs/fs/index.md", {}, "fs"),
    ("docs/pt/mbr.md", {}, "pt/mbr"),

    # index.md becomes directory path
    ("guests/linux/index.md", {}, "guests/linux"),
    ("builder/compiler/index.md", {}, "builder/compiler"),

    # README.md becomes directory path
    ("guests/linux/6.17/README.md", {}, "guests/linux/6.17"),
    ("data/fs/ext4/README.md", {}, "data/fs/ext4"),

    # root index/readme becomes empty string
    ("index.md", {}, ""),
    ("README.md", {}, ""),

    # regular .md files
    ("guests/linux/6.17/kernel.md", {}, "guests/linux/6.17/kernel"),
    ("something.md", {}, "something"),

    # explicit path override
    ("docs/fs/ext4.md", {"path": "filesystem/ext4"}, "filesystem/ext4"),
    ("random/location/file.md", {"path": "custom/path"}, "custom/path"),
    ("index.md", {"path": "root"}, "root"),

    # non-.md files pass through unchanged
    ("Makefile", {}, "Makefile"),
    ("scripts/build.sh", {}, "scripts/build.sh"),

    # docs prefix only at start
    ("guests/docs/README.md", {}, "guests/docs"),
])
def test_doc_path(file_path, meta, expected):
    assert doc_path(file_path, meta) == expected
