"""Architecture invariants for the real project catalogue."""

import os
import subprocess
import tempfile
from pathlib import Path

from qemount_build.catalogue import (
    build_graph,
    build_provides_index,
    load,
    resolve_provider_instances,
)
from qemount_build.provider_cache import provider_cache_container


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


def test_every_provider_instance_receives_its_automatic_cache():
    catalogue = project_catalogue()

    for path in catalogue["paths"]:
        for instance in resolve_provider_instances(path, catalogue, CONTEXT):
            expected = provider_cache_container()
            assert instance["context"]["QEMOUNT_CACHE_DIR"] == expected
            assert instance["meta"]["env"]["QEMOUNT_CACHE_DIR"] == expected


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


def test_darwin_consumers_share_the_declared_sdk_provider():
    sdk_provider = "sdk/darwin/11.3"

    for target in (
        "bin/x86_64-darwin/qemount-init",
        "bin/x86_64-darwin/simple9p",
        "bin/qemu-system/x86_64-darwin/qemu-system-x86_64",
    ):
        assert sdk_provider in graph_for(target)["nodes"]


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


def test_qemu_netbsd_architecture_profiles():
    helper = PACKAGE_DIR / "builder/run/qemu-netbsd/qemu-netbsd-arch.sh"
    expected = {
        "x86_64": (
            "qemu-system-x86_64||" "-drive file=boot,format=raw,if=virtio,readonly=on"
        ),
        "aarch64": "qemu-system-aarch64|-machine virt -cpu cortex-a57|-kernel boot",
    }

    for arch, profile in expected.items():
        result = subprocess.run(
            [
                "bash",
                "-c",
                'source "$1"; set_qemu_netbsd_arch_profile "$2" boot; '
                'printf "%s|%s|%s" "$QEMU_BIN" '
                '"${QEMU_MACHINE_ARGS[*]}" "${QEMU_BOOT_ARGS[*]}"',
                "qemu-profile",
                helper,
                arch,
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        assert result.stdout == profile


def test_qemount_binaries_do_not_embed_the_format_catalogue():
    for target in (
        "lib/x86_64-linux-gnu/libqemount.a",
        "bin/x86_64-linux-gnu/detect",
    ):
        assert "lib/format" not in graph_for(target)["nodes"]

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

    aros = graph_for("bin/qemu/i386-aros/qemount/aros.iso", context)
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
    assert "data/fs/basic.reiserfs" in providers

    reiserfs = graph_for("data/fs/basic.reiserfs", context)
    assert "bin/qemu/linux/6.12/kernel@aarch64-linux" in reiserfs["nodes"]
    assert "bin/qemu/linux/2.6/kernel@x86_64-linux" not in reiserfs["nodes"]


def test_haiku_and_dependents_are_unavailable_on_arm_hosts():
    context = {
        "BUILD_PLATFORM": "aarch64-linux",
        "BUILD_ARCH": "aarch64",
        "BUILD_OS": "linux",
        "JOBS": "1",
    }
    providers = buildable_providers(context)

    assert "docker:builder/compiler/haiku" not in providers
    assert "bin/x86_64-haiku/qemount-init" not in providers
    assert "bin/qemu/x86_64-haiku/qemount/haiku.image" not in providers
    assert "data/fs/basic.beos-bfs" not in providers


def test_netbsd_cross_build_matrix_and_host_native_disk_tools():
    arm_context = {
        "BUILD_PLATFORM": "aarch64-linux",
        "BUILD_ARCH": "aarch64",
        "BUILD_OS": "linux",
        "JOBS": "1",
    }

    for context in (CONTEXT, arm_context):
        providers = buildable_providers(context)
        assert "docker:builder/compiler/netbsd/10.0/x86_64" in providers
        assert "docker:builder/compiler/netbsd/10.0/aarch64" in providers
        assert "docker:builder/disk/netbsd" in providers
        assert "data/fs/basic.v7" in providers
        assert "data/pt/basic.disklabel" in providers
        assert "bin/x86_64-netbsd/simple9p" in providers
        assert "bin/aarch64-netbsd/simple9p" in providers
        assert "bin/qemu/x86_64-netbsd/10.0/boot/boot.img" in providers
        assert "bin/qemu/aarch64-netbsd/10.0/boot/netbsd" in providers
        assert "bin/qemu/aarch64-netbsd/10.0/boot/boot.img" not in providers

    arm_guest = graph_for("bin/qemu/aarch64-netbsd/10.0/boot/netbsd", CONTEXT)
    x86_guest = graph_for("bin/qemu/x86_64-netbsd/10.0/boot/netbsd", arm_context)
    arm_data = graph_for("data/fs/basic.v7", arm_context)

    assert "builder/compiler/netbsd/10.0@aarch64-netbsd" in arm_guest["nodes"]
    assert "builder/compiler/netbsd/10.0@x86_64-netbsd" in x86_guest["nodes"]
    assert "builder/compiler/netbsd/10.0@aarch64-netbsd" in arm_data["nodes"]
    assert (
        arm_guest["nodes"]["builder/compiler/netbsd/10.0@aarch64-netbsd"]["meta"][
            "env"
        ]["JOBS"]
        == "1"
    )


def test_9front_cross_build_matrix():
    arm_context = {
        "BUILD_PLATFORM": "aarch64-linux",
        "BUILD_ARCH": "aarch64",
        "BUILD_OS": "linux",
        "JOBS": "1",
    }

    for context in (CONTEXT, arm_context):
        providers = buildable_providers(context)
        assert "docker:builder/compiler/9front" in providers
        assert "bin/qemu/x86_64-9front/qemount/system/9front.iso" in providers
        assert "bin/qemu/aarch64-9front/qemount/system/9front.qcow2" in providers
        assert "bin/qemu/aarch64-9front/qemount/system/u-boot.bin" in providers

    arm_guest = graph_for(
        "bin/qemu/aarch64-9front/qemount/system/9front.qcow2", CONTEXT
    )
    x86_guest = graph_for(
        "bin/qemu/x86_64-9front/qemount/system/9front.iso", arm_context
    )

    assert "bin/qemu/9front/qemount/system@aarch64-9front" in arm_guest["nodes"]
    assert "bin/qemu/9front/qemount/system@x86_64-9front" in x86_guest["nodes"]
