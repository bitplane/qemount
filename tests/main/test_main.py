"""Tests for main.py CLI helpers."""

import json
from argparse import Namespace

from qemount_build.main import (
    normalize_target,
    expand_targets,
    get_jobs,
    get_default_arch,
    build_context,
    compatible_output_arches,
    run_command,
    cmd_dump,
    cmd_outputs,
    cmd_deps,
)


def test_run_command_handles_keyboard_interrupt(caplog):
    """Ctrl-C exits conventionally without exposing a Python traceback."""

    def interrupt(*args):
        raise KeyboardInterrupt

    assert run_command(interrupt, None, None, None) == 130
    assert "Interrupted" in caplog.text


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
    ctx = build_context("x86_64-linux")
    result = expand_targets(["data/fs/fat32"], cat, ctx)
    assert result == ["data/fs/fat32"]


def test_expand_targets_glob():
    """Glob patterns expand against outputs."""
    cat = make_catalogue(["data/fs/fat32", "data/fs/ext4", "data/pt/mbr"])
    ctx = build_context("x86_64-linux")
    result = expand_targets(["data/fs/*"], cat, ctx)
    assert result == ["data/fs/ext4", "data/fs/fat32"]


def test_expand_targets_strips_build():
    """Build prefix stripped before expansion."""
    cat = make_catalogue(["data/fs/fat32"])
    ctx = build_context("x86_64-linux")
    result = expand_targets(["build/data/fs/fat32"], cat, ctx)
    assert result == ["data/fs/fat32"]


def test_expand_targets_multiple():
    """Multiple patterns and literals combined."""
    cat = make_catalogue(["data/fs/fat32", "data/fs/ext4", "data/pt/mbr"])
    ctx = build_context("x86_64-linux")
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


def test_build_context_splits_canonical_platform():
    context = build_context("aarch64-linux")
    assert context["BUILD_ARCH"] == "aarch64"
    assert context["BUILD_OS"] == "linux"


def test_compatible_output_arches_include_32_bit_x86():
    assert compatible_output_arches("x86_64") == {"x86_64", "i386"}
    assert compatible_output_arches("aarch64") == {"aarch64"}


def test_cmd_dump(capsys):
    """cmd_dump outputs catalogue as JSON."""
    cat = make_catalogue(["data/fs/fat32"])
    ctx = build_context("x86_64-linux")
    args = Namespace()

    cmd_dump(args, cat, ctx)

    out = capsys.readouterr().out
    parsed = json.loads(out)
    assert "paths" in parsed


def test_cmd_outputs(capsys):
    """cmd_outputs lists all output paths."""
    cat = make_catalogue(["data/fs/fat32", "data/fs/ext4"])
    ctx = build_context("x86_64-linux")
    args = Namespace(verbose=False)

    cmd_outputs(args, cat, ctx)

    out = capsys.readouterr().out
    lines = out.strip().split("\n")
    assert "data/fs/fat32" in lines
    assert "data/fs/ext4" in lines


def test_cmd_outputs_verbose(capsys):
    """cmd_outputs -v shows provider path."""
    cat = make_catalogue(["data/fs/fat32"])
    ctx = build_context("x86_64-linux")
    args = Namespace(verbose=True)

    cmd_outputs(args, cat, ctx)

    out = capsys.readouterr().out
    assert "data/fs/fat32\tdata/fs/fat32" in out


def test_cmd_outputs_selects_compatible_and_neutral_by_default(capsys):
    cat = {
        "paths": {
            "neutral": {"meta": {"provides": {"data/file": {}}}, "sources": []},
            "tools": {
                "meta": {
                    "output_platforms": {
                        "x86_64-linux-musl": {
                            "provides": ["bin/x86_64-linux-musl/tool"]
                        },
                        "i386-aros": {"provides": ["bin/i386-aros/tool"]},
                        "aarch64-linux-musl": {
                            "provides": ["bin/aarch64-linux-musl/tool"]
                        },
                    }
                },
                "sources": [],
            },
        }
    }
    args = Namespace(verbose=False)
    cmd_outputs(args, cat, build_context("aarch64-linux"))
    lines = capsys.readouterr().out.splitlines()
    assert "data/file" in lines
    assert "bin/aarch64-linux-musl/tool" in lines
    assert "bin/x86_64-linux-musl/tool" not in lines
    assert "bin/i386-aros/tool" not in lines

    cmd_outputs(args, cat, build_context("x86_64-linux"))
    lines = capsys.readouterr().out.splitlines()
    assert "data/file" in lines
    assert "bin/x86_64-linux-musl/tool" in lines
    assert "bin/i386-aros/tool" in lines
    assert "bin/aarch64-linux-musl/tool" not in lines


def test_cmd_outputs_selects_explicit_output_arch(capsys):
    cat = {
        "paths": {
            "tools": {
                "meta": {
                    "output_platforms": {
                        "i386-aros": {"provides": ["bin/i386-aros/tool"]},
                        "aarch64-linux-musl": {
                            "provides": ["bin/aarch64-linux-musl/tool"]
                        },
                    }
                },
                "sources": [],
            }
        }
    }
    args = Namespace(verbose=False, output_arch=["i386"])
    cmd_outputs(args, cat, build_context("aarch64-linux"))
    lines = capsys.readouterr().out.splitlines()
    assert "bin/i386-aros/tool" in lines
    assert "bin/aarch64-linux-musl/tool" not in lines


def test_cmd_outputs_selects_guest_os_by_architecture(capsys):
    cat = {
        "paths": {
            "guests": {
                "meta": {
                    "output_platforms": {
                        "x86_64-haiku": {
                            "provides": ["bin/qemu/x86_64-haiku/guest"]
                        },
                        "aarch64-haiku": {
                            "provides": ["bin/qemu/aarch64-haiku/guest"]
                        },
                    }
                },
                "sources": [],
            }
        }
    }
    args = Namespace(verbose=False)
    cmd_outputs(args, cat, build_context("x86_64-linux"))
    lines = capsys.readouterr().out.splitlines()
    assert "bin/qemu/x86_64-haiku/guest" in lines
    assert "bin/qemu/aarch64-haiku/guest" not in lines


def test_cmd_outputs_all_shows_unavailable_reason(capsys):
    cat = make_catalogue(["legacy-output"])
    cat["paths"]["legacy-output"]["meta"]["build_platforms"] = {
        "x86_64-linux": {}
    }
    ctx = {
        "BUILD_PLATFORM": "aarch64-linux",
        "BUILD_ARCH": "aarch64",
        "BUILD_OS": "linux",
    }
    args = Namespace(verbose=True, include_unavailable=True)

    cmd_outputs(args, cat, ctx)

    out = capsys.readouterr().out
    assert "legacy-output\tlegacy-output\tunavailable:" in out
    assert "build platform aarch64-linux" in out


def test_cmd_deps(capsys):
    """cmd_deps shows build order."""
    cat = make_catalogue(["data/fs/fat32"])
    ctx = build_context("x86_64-linux")
    args = Namespace(targets=["data/fs/fat32"], order=False)

    result = cmd_deps(args, cat, ctx)

    assert result == 0
    out = capsys.readouterr().out
    assert "data/fs/fat32" in out


def test_cmd_deps_order(capsys):
    """cmd_deps --order outputs one path per line."""
    cat = make_catalogue(["data/fs/fat32"])
    ctx = build_context("x86_64-linux")
    args = Namespace(targets=["data/fs/fat32"], order=True)

    result = cmd_deps(args, cat, ctx)

    assert result == 0
    out = capsys.readouterr().out
    assert out.strip() == "data/fs/fat32"


def test_cmd_deps_no_match():
    """cmd_deps returns error for non-matching glob."""
    cat = make_catalogue(["data/fs/fat32"])
    ctx = build_context("x86_64-linux")
    args = Namespace(targets=["data/pt/*"], order=False)

    result = cmd_deps(args, cat, ctx)

    assert result == 1


def test_cmd_deps_not_found():
    """cmd_deps returns error for missing target."""
    cat = make_catalogue(["data/fs/fat32"])
    ctx = build_context("x86_64-linux")
    args = Namespace(targets=["data/fs/ext4"], order=False)

    result = cmd_deps(args, cat, ctx)

    assert result == 1
