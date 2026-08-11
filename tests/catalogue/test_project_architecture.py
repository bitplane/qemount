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


def test_qemu_runtime_firmware_is_complete():
    providers = buildable_providers()
    runner = (PACKAGE_DIR / "builder/run/qemu-linux/run.sh").read_text()

    assert "bin/qemu-system/firmware/efi-virtio.rom" in providers
    assert '-L "$FIRMWARE_DIR"' in runner


def test_qemount_binaries_do_not_embed_the_format_catalogue():
    for target in (
        "lib/x86_64-linux-gnu/libqemount.a",
        "bin/x86_64-linux-gnu/detect",
    ):
        assert "lib/format" not in graph_for(target)["nodes"]


def test_linux_rootfs_creates_runtime_mountpoints():
    build_script = (PACKAGE_DIR / "bin/qemu/linux/rootfs/build.sh").read_text()

    for path in ("dev", "mnt", "proc", "sys", "tmp"):
        assert f'"$ROOT/{path}"' in build_script


def test_reiser4_fixture_uses_portable_block_size():
    build_script = (PACKAGE_DIR / "data/fs/reiser4/buildfs.sh").read_text()

    assert "mkfs.reiser4 --block-size 4096" in build_script


def test_dragonfly_compiler_image_contains_its_completed_object_tree():
    dockerfile = (
        PACKAGE_DIR / "builder/compiler/dragonfly/6.4.2/Dockerfile"
    ).read_text()
    system = (
        PACKAGE_DIR / "bin/qemu/dragonfly/6.4.2/system/build.sh"
    ).read_text()

    assert 'cp -a "$CACHE_DIR/obj" /usr/obj' in dockerfile
    assert '"$@" crossworld' in dockerfile
    assert '"$@" _includes' in dockerfile
    assert '"$@" _libraries' in dockerfile
    assert "buildworld" not in dockerfile
    assert "installworld" not in system
    assert 'done < /build/runtime-files.txt' in system
    assert '-m "$DRAGONFLY_SRC/share/mk"' in system
    assert '-DSYSBUILD -DNOMAN -DNOPIC -DNOPROFILE' in system
    assert 'world_make -C "$DRAGONFLY_SRC/libexec/rtld-elf" install' in system
    for target in ("depend", "all", "install"):
        assert f'world_make -C "$DRAGONFLY_SRC/$path" {target}' in system


def test_netbsd_compiler_image_contains_downstream_host_tools():
    dockerfile = (
        PACKAGE_DIR / "builder/compiler/netbsd/10.0/Dockerfile"
    ).read_text()

    assert 'cp -a "$CACHE_DIR/obj/tools/makefs/makefs"' in dockerfile


def test_aros_compiler_image_contains_its_bootstrap_closure():
    dockerfile = (
        PACKAGE_DIR / "builder/compiler/aros/pc-i386/Dockerfile"
    ).read_text()
    system = (
        PACKAGE_DIR / "bin/qemu/aros/pc-i386/system/build.sh"
    ).read_text()

    assert "INSTALL_DIR=/opt/aros-toolchain" in dockerfile
    assert "/opt/aros-bootstrap/bin/pc-i386-tiny/AROS" in dockerfile
    assert "HOST_TOOLS=bin/linux-${BUILD_ARCH}/tools" in dockerfile
    assert "$BUILD_DIR/$HOST_TOOLS/collect-aros" in dockerfile
    assert "/opt/aros-bootstrap/$HOST_TOOLS/" in dockerfile
    assert "linux-x86_64" not in dockerfile
    assert 'cp -a /opt/aros-bootstrap/. "$GUEST_BUILD_DIR/"' in system


def test_aros_system_builds_only_its_declared_appliance_closure():
    directory = PACKAGE_DIR / "bin/qemu/aros/pc-i386/system"
    build_script = (directory / "build.sh").read_text()
    dockerfile = (directory / "Dockerfile").read_text()
    metadata = (directory / "index.md").read_text()
    targets = {
        line
        for line in (directory / "mmake-targets.txt").read_text().splitlines()
        if line and not line.startswith("#")
    }
    prepare_targets = {
        line
        for line in (directory / "mmake-prepare-targets.txt").read_text().splitlines()
        if line and not line.startswith("#")
    }
    files = {
        line
        for line in (directory / "system-files.txt").read_text().splitlines()
        if line and not line.startswith("#")
    }
    outputs = (directory / "mmake-outputs.txt").read_text()
    runtime_files = (
        PACKAGE_DIR / "bin/qemu/aros/pc-i386/boot/runtime-files.txt"
    ).read_text().splitlines()

    assert 'done < /build/mmake-targets.txt' in build_script
    assert 'make -j"$BUILD_JOBS" "$target"' in build_script
    assert 'done < /build/mmake-outputs.txt' in build_script
    assert 'done < /build/system-files.txt' in build_script
    assert "bootiso-pc-i386" not in build_script
    assert "AROS-complete" not in build_script
    assert '\nmake -j"$BUILD_JOBS"\n' not in build_script
    assert "mmake-prepare-targets.txt mmake-targets.txt" in dockerfile
    assert "mesa" not in metadata.lower()
    assert {
        "bootloader-grub2-pc-i386",
        "kernel-bootstrap-pc-compress-quick",
        "kernel-pc-i386-kernel-compress-quick",
        "kernel-bsp-pc-i386-compress-quick",
        "kernel-package-base-compress-quick",
        "kernel-package-fs-compress-quick",
        "kernel-fs-pfs3-quick",
        "workbench-libs-dos-catalogs",
        "linklibs-romhack",
        "linklibs-loadseg",
        "includes-compositor-copy",
        "workbench-devs-serial-quick",
        "workbench-fs-port-quick",
        "includes-asm_h",
        "kernel-entropy-includes",
        "workbench-libs-fd-includes",
        "compiler-posixc-quick",
        "compiler-stdc-genwcharsupport",
        "compiler-stdc-quick",
    } <= targets
    assert 'make -j"$BUILD_JOBS" hidd-serial-stubs' in build_script
    assert {
        "boot/pc-tiny/bootstrap.xz",
        "boot/pc-tiny/kernel.xz",
        "boot/aros-fs.pkg.xz",
        "C/Automount",
        "Devs/serial.device",
        "L/pfs3-handler",
        "L/sfs-handler",
        "Libs/partition.library",
        "C/Copy",
        "C/DiskChange",
        "C/MakeDir",
        "C/MakeLink",
        "C/Type",
        "C/Wait",
    } <= files
    assert 'printf \'%s\\n\' "$TARGET_CPU" >"$STAGING_DIR/AROS.boot"' in build_script
    assert 'make -j"$BUILD_JOBS" "$target"' in build_script
    assert {
        "kernel-task-includes-dirs",
        "kernel-hidd-telemetry-includes-dirs",
        "kernel-hidd-power-includes-dirs",
        "kernel-fs-pfs3-includes-dirs",
    } <= prepare_targets
    assert 'xargs -r -n 32 "$MMAKE"' in build_script
    assert 'export MMAKE_CONFIG="$GUEST_BUILD_DIR/mmake.config"' in build_script
    assert 'gen/lib/hidd/serial_stubs.o' in build_script
    assert "AROS.boot" in runtime_files
    assert (
        "workbench-c-quick C/Automount C/DiskChange C/MakeDir C/MakeLink C/Mount C/Shutdown C/Type C/Wait"
        in outputs
    )
    assert "workbench-c-sh-quick C/Assign C/Copy" in outputs
    assert "workbench-c-shellcommands-quick C/Echo" in outputs


def test_aros_images_enforce_their_size_budgets():
    system = (
        PACKAGE_DIR / "bin/qemu/aros/pc-i386/system/build.sh"
    ).read_text()
    appliance = (
        PACKAGE_DIR / "bin/qemu/aros/pc-i386/boot/build.sh"
    ).read_text()

    assert "16777216" in system
    assert "4194304" in appliance


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
    assert "docker:builder/compiler/haiku/r1beta5-sdk" not in providers
    assert "bin/x86_64-haiku/qemount-init" not in providers
    assert "bin/qemu/x86_64-haiku/qemount/boot/haiku.image" not in providers
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


def test_netbsd_rootfs_uses_target_device_database():
    build_script = (PACKAGE_DIR / "bin/qemu/netbsd/10.0/rootfs/build.sh").read_text()
    init_script = (
        PACKAGE_DIR / "bin/qemu/netbsd/10.0/rootfs/root/sbin/init"
    ).read_text()

    assert "$DESTDIR/dev/MAKEDEV" in build_script
    assert "/bin/sh /MAKEDEV" in init_script
    assert "kern.rawpartition" in init_script
    assert "mknod /dev/ld" not in init_script


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
