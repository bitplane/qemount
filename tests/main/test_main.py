"""Tests for main.py CLI helpers."""

import json
from argparse import Namespace
from io import StringIO

from qemount_build.main import (
    normalize_target,
    expand_targets,
    get_jobs,
    get_default_arch,
    cmd_dump,
    cmd_outputs,
    cmd_deps,
)


def test_normalize_target_strips_build_prefix():
    """Strips build/ prefix for autocomplete convenience."""
    assert normalize_target("build/data/fs/fat32") == "data/fs/fat32"


def test_normalize_target_leaves_other_paths():
    """Leaves non-build/ paths unchanged."""
    assert normalize_target("data/fs/fat32") == "data/fs/fat32"


def test_normalize_target_partial_match():
    """Only strips exact 'build/' prefix."""
    assert normalize_target("builder/disk") == "builder/disk"


def make_catalogue(outputs):
    """Create minimal catalogue with given output paths."""
    return {
        "paths": {
            path: {"meta": {"provides": {path: {}}}, "sources": [f"{path}/index.md"]}
            for path in outputs
        }
    }


def test_expand_targets_literal():
    """Literal targets pass through."""
    cat = make_catalogue(["data/fs/fat32", "data/fs/ext4"])
    ctx = {"ARCH": "x86_64"}
    result = expand_targets(["data/fs/fat32"], cat, ctx)
    assert result == ["data/fs/fat32"]


def test_expand_targets_glob():
    """Glob patterns expand against outputs."""
    cat = make_catalogue(["data/fs/fat32", "data/fs/ext4", "data/pt/mbr"])
    ctx = {"ARCH": "x86_64"}
    result = expand_targets(["data/fs/*"], cat, ctx)
    assert result == ["data/fs/ext4", "data/fs/fat32"]


def test_expand_targets_strips_build():
    """Build prefix stripped before expansion."""
    cat = make_catalogue(["data/fs/fat32"])
    ctx = {"ARCH": "x86_64"}
    result = expand_targets(["build/data/fs/fat32"], cat, ctx)
    assert result == ["data/fs/fat32"]


def test_expand_targets_multiple():
    """Multiple patterns and literals combined."""
    cat = make_catalogue(["data/fs/fat32", "data/fs/ext4", "data/pt/mbr"])
    ctx = {"ARCH": "x86_64"}
    result = expand_targets(["data/pt/mbr", "data/fs/*"], cat, ctx)
    assert result == ["data/pt/mbr", "data/fs/ext4", "data/fs/fat32"]


def test_get_jobs_returns_positive():
    """get_jobs returns at least 1."""
    jobs = get_jobs()
    assert jobs >= 1
    assert jobs <= 16


def test_get_default_arch_returns_string():
    """get_default_arch returns a string."""
    arch = get_default_arch()
    assert isinstance(arch, str)
    assert len(arch) > 0


def test_cmd_dump(capsys):
    """cmd_dump outputs catalogue as JSON."""
    cat = make_catalogue(["data/fs/fat32"])
    ctx = {"ARCH": "x86_64"}
    args = Namespace()

    cmd_dump(args, cat, ctx)

    out = capsys.readouterr().out
    parsed = json.loads(out)
    assert "paths" in parsed


def test_cmd_outputs(capsys):
    """cmd_outputs lists all output paths."""
    cat = make_catalogue(["data/fs/fat32", "data/fs/ext4"])
    ctx = {"ARCH": "x86_64"}
    args = Namespace(verbose=False)

    cmd_outputs(args, cat, ctx)

    out = capsys.readouterr().out
    lines = out.strip().split("\n")
    assert "data/fs/fat32" in lines
    assert "data/fs/ext4" in lines


def test_cmd_outputs_verbose(capsys):
    """cmd_outputs -v shows provider path."""
    cat = make_catalogue(["data/fs/fat32"])
    ctx = {"ARCH": "x86_64"}
    args = Namespace(verbose=True)

    cmd_outputs(args, cat, ctx)

    out = capsys.readouterr().out
    assert "data/fs/fat32\tdata/fs/fat32" in out


def test_cmd_deps(capsys):
    """cmd_deps shows build order."""
    cat = make_catalogue(["data/fs/fat32"])
    ctx = {"ARCH": "x86_64"}
    args = Namespace(targets=["data/fs/fat32"], order=False)

    result = cmd_deps(args, cat, ctx)

    assert result == 0
    out = capsys.readouterr().out
    assert "data/fs/fat32" in out


def test_cmd_deps_order(capsys):
    """cmd_deps --order outputs one path per line."""
    cat = make_catalogue(["data/fs/fat32"])
    ctx = {"ARCH": "x86_64"}
    args = Namespace(targets=["data/fs/fat32"], order=True)

    result = cmd_deps(args, cat, ctx)

    assert result == 0
    out = capsys.readouterr().out
    assert out.strip() == "data/fs/fat32"


def test_cmd_deps_no_match():
    """cmd_deps returns error for non-matching glob."""
    cat = make_catalogue(["data/fs/fat32"])
    ctx = {"ARCH": "x86_64"}
    args = Namespace(targets=["data/pt/*"], order=False)

    result = cmd_deps(args, cat, ctx)

    assert result == 1


def test_cmd_deps_not_found():
    """cmd_deps returns error for missing target."""
    cat = make_catalogue(["data/fs/fat32"])
    ctx = {"ARCH": "x86_64"}
    args = Namespace(targets=["data/fs/ext4"], order=False)

    result = cmd_deps(args, cat, ctx)

    assert result == 1
