#!/usr/bin/env python3

import sys

import pexpect


output_arch, system_image, source_iso, output_image = sys.argv[1:]

if output_arch == "x86_64":
    objtype = "amd64"
    compiler = "6"
    kernel_dir = "pc64"
    image = "mountin.amd64.iso"
    plan9_ini = "plan9-amd64.ini"
elif output_arch == "aarch64":
    objtype = "arm64"
    compiler = "7"
    kernel_dir = "arm64"
    image = "mountin.arm64.qcow2"
    plan9_ini = "plan9-arm64.ini"
else:
    raise ValueError(f"unsupported 9front architecture: {output_arch}")

runtime_executables = [
    f"/{objtype}/init",
    *[
        f"/{objtype}/bin/{name}"
        for name in (
            "9660srv",
            "awk",
            "basename",
            "bind",
            "cat",
            "cmp",
            "cp",
            "cwfs64x",
            "dd",
            "dossrv",
            "echo",
            "exportfs",
            "gefs",
            "grep",
            "hjfs",
            "ls",
            "mkdir",
            "mount",
            "mkpaqfs",
            "paqfs",
            "ps",
            "pwd",
            "mountin-fsprobe",
            "ramfs",
            "rc",
            "rm",
            "sleep",
            "test",
            "tar",
            "unmount",
            "xd",
        )
    ],
    *[f"/{objtype}/bin/aux/{name}" for name in ("flashfs", "mkflashfs")],
    *[f"/{objtype}/bin/disk/{name}" for name in ("edisk", "fdisk", "mbr", "prep")],
    *[f"/{objtype}/bin/fs/{name}" for name in ("32vfs", "v10fs", "v6fs")],
    "/rc/bin/diskparts",
    "/rc/bin/mountin",
    "/rc/bin/mountin-init",
    "/rc/bin/mountin-mount",
    "/rc/bin/termrc",
]

qemu = pexpect.spawn(
    "qemu-system-x86_64",
    [
        "-machine",
        "q35,accel=kvm:tcg",
        "-cpu",
        "max",
        "-m",
        "1024",
        "-smp",
        "2",
        "-display",
        "none",
        "-monitor",
        "none",
        "-serial",
        "stdio",
        "-no-reboot",
        "-drive",
        f"file={system_image},if=virtio,format=qcow2",
        "-drive",
        f"file={source_iso},media=cdrom,format=raw",
        "-drive",
        f"file={output_image},if=virtio,format=raw",
    ],
    encoding="utf-8",
    codec_errors="replace",
    timeout=3600,
)
qemu.logfile_read = sys.stdout


def run(command: str) -> None:
    qemu.sendline(
        f"{{{command}}}; command_status=$status; "
        "if(~ $\"command_status '') echo MOUNTIN_^COMMAND_OK; "
        "if(! ~ $\"command_status '') echo MOUNTIN_^COMMAND_FAILED"
    )
    result = qemu.expect(
        [r"MOUNTIN_COMMAND_OK", r"MOUNTIN_COMMAND_FAILED"], timeout=3600
    )
    qemu.expect(r"term% ", timeout=3600)
    if result != 0:
        raise RuntimeError(f"9front command failed: {command}")


try:
    qemu.expect("bootargs is")
    qemu.sendline("local!/dev/sdF0/fs")
    qemu.expect("user")
    qemu.sendline("glenda")
    qemu.expect(r"term% ")

    commands = [
        "mkdir -p /n/src /n/out",
        "9660srv -f /dev/sdE0/data mountinsrc",
        "mount /srv/mountinsrc /n/src",
        "dossrv -f /dev/sdG0/data mountinout",
        "mount -c /srv/mountinout /n/out",
        "mkdir -p /usr/glenda/mountin-build",
        "cd /usr/glenda/mountin-build",
        "tar xzf /n/src/9front-*.tar.gz",
        "cd 9front-*",
        "source_root=`{pwd}",
        f"cp /n/src/mountin/{plan9_ini} $source_root/sys/lib/dist/cfg/plan9.ini",
        "cp /n/src/mountin/mountin.rc $source_root/rc/bin/mountin",
        "cp /n/src/mountin/mountin-mount.rc $source_root/rc/bin/mountin-mount",
        "cp /n/src/mountin/mountin-init.rc $source_root/rc/bin/mountin-init",
        "chmod 775 $source_root/rc/bin/mountin $source_root/rc/bin/mountin-mount $source_root/rc/bin/mountin-init",
        "bind -bc $source_root /",
        "cd /",
        ". /sys/lib/rootstub",
    ]

    if output_arch == "aarch64":
        commands.extend(
            [
                "cd /sys/src; objtype=amd64; mk libs",
                "for(i in /sys/src/cmd/7[acl]) @{cd $i; mk install}",
            ]
        )

    commands.extend(
        [
            f"objtype={objtype}; rc /n/src/mountin/mountin-build.rc {objtype} {compiler}",
            "cd /sys/src/cmd/disk/sacfs",
            f"objtype={objtype}; mk mksacfs.install",
            f"cp /{objtype}/bin/disk/mksacfs /n/out/mksacfs",
            f"rm /{objtype}/bin/disk/mksacfs",
            f"objtype={objtype}; mk clean",
        ]
    )

    if output_arch == "x86_64":
        commands.extend(
            [
                "cd /sys/src/boot/pc",
                "mk install",
                "mk clean",
                "cd /sys/src/boot/efi",
                "mk install",
                "mk clean",
            ]
        )
    commands.extend(
        [
            f"cd /sys/src/9/{kernel_dir}",
            f"objtype={objtype}; mk install",
            f"objtype={objtype}; mk clean",
        ]
    )
    if output_arch == "aarch64":
        commands.append("cd /sys/src/boot/qemu; mk")
    commands.extend(
        [
            "mkdir -p /n/src9",
            "bind / /n/src9",
            "cd /sys/lib/dist",
            "sed 's!^proto=.*!proto=/n/src/mountin/mountin.proto!; "
            f"s!^bootproto=.*!bootproto=/n/src/mountin/mountin-{objtype}.proto!' "
            "mkfile >/tmp/mountin-dist-mkfile",
            "bind /tmp/mountin-dist-mkfile /sys/lib/dist/mkfile",
            f"mk /tmp/{image}",
        ]
    )

    if output_arch == "x86_64":
        commands.extend(
            [
                "mkdir -p /n/verify",
                f"9660srv -f /tmp/{image} mountinverify",
                "mount /srv/mountinverify /n/verify",
            ]
        )
    else:
        commands.extend(
            [
                "mkdir -p /n/mountin-qcow /n/mountin-parts /n/mountin-boot /n/verify",
                f"disk/qcowfs -m /n/mountin-qcow -s mountinqcow /tmp/{image}",
                "disk/partfs -m /n/mountin-parts -s mountinparts /n/mountin-qcow/data",
                "diskparts /n/mountin-parts/sdXX",
                "dossrv -f /n/mountin-parts/sdXX/dos mountinboot",
                "mount -c /srv/mountinboot /n/mountin-boot",
                f"cp /n/src/mountin/{plan9_ini} /n/mountin-boot/plan9.ini",
                "unmount /n/mountin-boot",
                "hjfs -f /n/mountin-parts/sdXX/fs -n mountinverify -S -m 16",
                "mount /srv/mountinverify /n/verify",
            ]
        )

    commands.extend(
        [
            f"cmp /n/src/mountin/{plan9_ini} /n/verify/cfg/plan9.ini",
            "cmp /n/src/mountin/mountin.rc /n/verify/rc/bin/mountin",
            "cmp /n/src/mountin/mountin-mount.rc /n/verify/rc/bin/mountin-mount",
            "cmp /n/src/mountin/mountin-init.rc /n/verify/rc/bin/mountin-init",
            "cmp /n/src/mountin/mountin-init.rc /n/verify/rc/bin/termrc",
            "test -x /n/verify/rc/bin/mountin",
            "test -x /n/verify/rc/bin/mountin-mount",
            "test -x /n/verify/rc/bin/mountin-init",
            "test -f /n/verify/rc/lib/rcmain",
            f"test -x /n/verify/{objtype}/bin/mountin-fsprobe",
            *[f"test -x /n/verify{path}" for path in runtime_executables],
            "test ! -e /n/verify/dist/9front",
            "test ! -e /n/verify/sys/src",
            f"test ! -e /n/verify/{objtype}/bin/gs",
            f"test ! -e /n/verify/{objtype}/lib",
            "test ! -e /n/verify/lib/font",
            "unmount /n/verify",
        ]
    )

    if output_arch == "aarch64":
        commands.extend(
            [
                "echo halt >>/srv/mountinverify.cmd",
                "while(test -e /srv/mountinverify.cmd) sleep 1; "
                "test ! -e /srv/mountinverify.cmd",
            ]
        )

    commands.extend(
        [
            f"cp /tmp/{image} /n/out/9front.{image.rsplit('.', 1)[1]}",
            "echo MOUNTIN_BUILD_OK >/n/out/proof.txt",
            "unmount /n/out",
        ]
    )

    for command in commands:
        run(command)
finally:
    qemu.terminate(force=True)
    qemu.wait()
