"""Architecture invariants for the real project catalogue."""

import os
import subprocess
import tempfile
from pathlib import Path

from qemount_build.catalogue import build_graph, build_provides_index, load


PACKAGE_DIR = Path(__file__).parents[2] / "src" / "qemount_build"
CONTEXT = {
    "BUILD_PLATFORM": "x86_64-linux",
    "BUILD_ARCH": "x86_64",
    "BUILD_OS": "linux",
    "JOBS": "1",
}


def project_catalogue():
    return load(PACKAGE_DIR)


def buildable_providers(context: dict = CONTEXT):
    with tempfile.TemporaryDirectory() as tmp:
        return build_provides_index(project_catalogue(), context, Path(tmp))


def graph_for(target: str, context: dict = CONTEXT):
    with tempfile.TemporaryDirectory() as tmp:
        return build_graph(
            [target],
            project_catalogue(),
            context,
            Path(tmp),
        )


def test_qemu_zig_wrapper_translates_darwin_target(tmp_path):
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    zig = bin_dir / "zig"
    zig.write_text("#!/bin/sh\nexit 0\n")
    zig.chmod(0o755)
    wrappers = tmp_path / "wrappers"

    subprocess.run(
        [
            "bash",
            PACKAGE_DIR / "builder/qemu/zig-wrapper.sh",
            "x86_64-darwin",
            wrappers,
        ],
        env={**os.environ, "PATH": f"{bin_dir}:{os.environ['PATH']}"},
        check=True,
    )

    compiler = (wrappers / "cc").read_text()
    assert "-target x86_64-macos" in compiler
    assert "/opt/x86_64-darwin" in compiler


def test_qemu_linux_architecture_profiles():
    helper = PACKAGE_DIR / "builder/disk/qemu/qemu-linux-arch.sh"
    expected = {
        "x86_64": "qemu-system-x86_64||ttyS0",
        "aarch64": "qemu-system-aarch64|-machine virt -cpu cortex-a57|ttyAMA0",
        "arm": "qemu-system-arm|-machine virt -cpu cortex-a15|ttyAMA0",
    }

    for arch, profile in expected.items():
        result = subprocess.run(
            [
                "bash",
                "-c",
                'source "$1"; set_qemu_linux_arch_profile "$2"; '
                'printf "%s|%s|%s" "$QEMU_BIN" '
                '"${QEMU_MACHINE_ARGS[*]}" "$QEMU_CONSOLE"',
                "qemu-profile",
                helper,
                arch,
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        assert result.stdout == profile


def test_reiser4_fixture_uses_portable_block_size():
    build_script = (PACKAGE_DIR / "data/fs/reiser4/buildfs.sh").read_text()

    assert "mkfs.reiser4 --block-size 4096" in build_script


def test_amiga_manifest_has_separate_provider_from_generic_template():
    providers = buildable_providers()

    assert providers["data/templates/basic.tar"] == "data/templates"
    assert providers["data/templates/basic.amiga"] == "data/templates/amiga"


def test_only_amiga_fixtures_depend_on_amiga_manifest():
    for target in (
        "data/fs/basic.amiga-pfs",
        "data/fs/basic.amiga-sfs",
    ):
        assert "data/templates/amiga" in graph_for(target)["nodes"]

    for target in (
        "data/arc/basic.zip",
        "data/fs/basic.ext4",
    ):
        assert "data/templates/amiga" not in graph_for(target)["nodes"]


def test_fixed_arch_guests_resolve_on_arm_hosts():
    context = {
        "BUILD_PLATFORM": "aarch64-linux",
        "BUILD_ARCH": "aarch64",
        "BUILD_OS": "linux",
        "JOBS": "1",
    }
    providers = buildable_providers(context)

    assert providers["bin/i386-aros/simple9p"] == "bin/aros/simple9p"
    assert providers["bin/x86_64-darwin/simple9p"] == "bin/darwin/simple9p"

    aros = graph_for("bin/qemu/i386-aros/boot/aros.iso", context)
    darwin = graph_for(
        "bin/qemu/x86_64-darwin/puredarwin/appliance/puredarwin.raw",
        context,
    )

    assert "bin/aros/simple9p@i386-aros" in aros["nodes"]
    assert "bin/darwin/simple9p@x86_64-darwin" in darwin["nodes"]


def test_linux_2_6_and_dependents_are_unavailable_on_arm_hosts():
    context = {
        "BUILD_PLATFORM": "aarch64-linux",
        "BUILD_ARCH": "aarch64",
        "BUILD_OS": "linux",
        "JOBS": "1",
    }
    providers = buildable_providers(context)

    assert "docker:builder/compiler/linux/2" not in providers
    assert "bin/qemu/aarch64-linux/2.6/kernel" not in providers
    assert "bin/qemu/aarch64-linux/2.6/boot/kernel" not in providers
    assert "data/fs/basic.reiserfs" not in providers


def test_haiku_and_dependents_are_unavailable_on_arm_hosts():
    context = {
        "BUILD_PLATFORM": "aarch64-linux",
        "BUILD_ARCH": "aarch64",
        "BUILD_OS": "linux",
        "JOBS": "1",
    }
    providers = buildable_providers(context)

    assert "docker:builder/compiler/haiku" not in providers
    assert "docker:builder/compiler/haiku/r1beta5-sdk" not in providers
    assert "bin/x86_64-haiku/qemount-init" not in providers
    assert "bin/qemu/x86_64-haiku/qemount/boot/haiku.image" not in providers
    assert "data/fs/basic.beos-bfs" not in providers


def test_netbsd_toolchain_and_dependents_are_unavailable_on_arm_hosts():
    context = {
        "BUILD_PLATFORM": "aarch64-linux",
        "BUILD_ARCH": "aarch64",
        "BUILD_OS": "linux",
        "JOBS": "1",
    }
    providers = buildable_providers(context)

    assert "docker:builder/compiler/netbsd/10.0" not in providers
    assert "docker:builder/disk/netbsd" not in providers
    assert "data/fs/basic.v7" not in providers
    assert "data/pt/basic.disklabel" not in providers
    assert "bin/qemu/aarch64-netbsd/10.0/kernel/netbsd.gdb" not in providers
    assert "bin/qemu/aarch64-netbsd/10.0/boot/boot.img" not in providers
