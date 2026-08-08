#!/usr/bin/env python3

import sys

import pexpect


output_arch, system_image, source_iso, output_image = sys.argv[1:]

if output_arch == "x86_64":
    objtype = "amd64"
    compiler = "6"
    kernel_dir = "pc64"
    image = "qemount.amd64.iso"
    plan9_ini = "plan9-amd64.ini"
elif output_arch == "aarch64":
    objtype = "arm64"
    compiler = "7"
    kernel_dir = "arm64"
    image = "qemount.arm64.qcow2"
    plan9_ini = "plan9-arm64.ini"
else:
    raise ValueError(f"unsupported 9front architecture: {output_arch}")

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
        "if(~ $\"command_status '') echo QEMOUNT_^COMMAND_OK; "
        "if(! ~ $\"command_status '') echo QEMOUNT_^COMMAND_FAILED"
    )
    result = qemu.expect(
        [r"QEMOUNT_COMMAND_OK", r"QEMOUNT_COMMAND_FAILED"], timeout=3600
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
        "9660srv -f /dev/sdE0/data qemountsrc",
        "mount /srv/qemountsrc /n/src",
        "dossrv -f /dev/sdG0/data qemountout",
        "mount -c /srv/qemountout /n/out",
        "mkdir -p /usr/glenda/qemount-build",
        "cd /usr/glenda/qemount-build",
        "tar xzf /n/src/9front-*.tar.gz",
        "cd 9front-*",
        "source_root=`{pwd}",
        f"cp /n/src/qemount/{plan9_ini} $source_root/sys/lib/dist/cfg/plan9.ini",
        "cp /n/src/qemount/qemount.rc $source_root/rc/bin/qemount",
        "cp /n/src/qemount/qemount-mount.rc $source_root/rc/bin/qemount-mount",
        "cp /n/src/qemount/qemount-init.rc $source_root/rc/bin/qemount-init",
        "chmod 775 $source_root/rc/bin/qemount $source_root/rc/bin/qemount-mount $source_root/rc/bin/qemount-init",
        "bind -bc $source_root /",
        "cd /",
        ". /sys/lib/rootstub",
    ]

    if output_arch == "aarch64":
        commands.append("for(i in /sys/src/cmd/7[acl]) @{cd $i; mk install}")

    commands.extend(
        [
            "cd /sys/src",
            f"objtype={objtype}; mk nuke",
            f"objtype={objtype}; mk libs",
            f"objtype={objtype}; mk install",
            f"objtype={objtype}; mk clean",
            "cd /usr/glenda/qemount-build",
            f"{compiler}c /n/src/qemount/qemount-fsprobe.c",
            f"{compiler}l -o /{objtype}/bin/qemount-fsprobe qemount-fsprobe.{compiler}",
            f"rm qemount-fsprobe.{compiler}",
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
            "mkdir -p /n/src9",
            "bind / /n/src9",
            "cd /sys/lib/dist",
            f"mk /tmp/{image}",
        ]
    )

    if output_arch == "x86_64":
        commands.extend(
            [
                "mkdir -p /n/verify",
                f"9660srv -f /tmp/{image} qemountverify",
                "mount /srv/qemountverify /n/verify",
            ]
        )
    else:
        commands.extend(
            [
                "mkdir -p /n/qemount-qcow /n/qemount-parts /n/qemount-boot /n/verify",
                f"disk/qcowfs -m /n/qemount-qcow -s qemountqcow /tmp/{image}",
                "disk/partfs -m /n/qemount-parts -s qemountparts /n/qemount-qcow/data",
                "dossrv -f /n/qemount-parts/sdXX/dos qemountboot",
                "mount -c /srv/qemountboot /n/qemount-boot",
                f"cp /n/src/qemount/{plan9_ini} /n/qemount-boot/plan9.ini",
                "unmount /n/qemount-boot",
                "hjfs -f /n/qemount-parts/sdXX/fs -n qemountverify -S -m 16",
                "mount /srv/qemountverify /n/verify",
            ]
        )

    commands.extend(
        [
            f"cmp /n/src/qemount/{plan9_ini} /n/verify/cfg/plan9.ini",
            "cmp /n/src/qemount/qemount.rc /n/verify/rc/bin/qemount",
            "cmp /n/src/qemount/qemount-mount.rc /n/verify/rc/bin/qemount-mount",
            "cmp /n/src/qemount/qemount-init.rc /n/verify/rc/bin/qemount-init",
            "test -x /n/verify/rc/bin/qemount",
            "test -x /n/verify/rc/bin/qemount-mount",
            "test -x /n/verify/rc/bin/qemount-init",
            f"test -x /n/verify/{objtype}/bin/qemount-fsprobe",
            "unmount /n/verify",
        ]
    )

    if output_arch == "aarch64":
        commands.extend(
            [
                "echo halt >>/srv/qemountverify.cmd",
                "while(test -e /srv/qemountverify.cmd) sleep 1",
            ]
        )

    commands.extend(
        [
            f"cp /tmp/{image} /n/out/9front.{image.rsplit('.', 1)[1]}",
            "echo QEMOUNT_BUILD_OK >/n/out/proof.txt",
            "unmount /n/out",
        ]
    )

    for command in commands:
        run(command)
finally:
    qemu.terminate(force=True)
    qemu.wait()
