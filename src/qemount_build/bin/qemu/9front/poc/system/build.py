#!/usr/bin/env python3

import sys

import pexpect


system_image, source_iso, output_image = sys.argv[1:]

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
    qemu.sendline(command)
    qemu.expect(r"term% ", timeout=3600)


try:
    qemu.expect("bootargs is")
    qemu.sendline("local!/dev/sdF0/fs")
    qemu.expect("user")
    qemu.sendline("glenda")
    qemu.expect(r"term% ")

    for command in [
        "mkdir -p /n/src /n/out",
        "9660srv -f /dev/sdE0/data qemountsrc",
        "mount /srv/qemountsrc /n/src",
        "dossrv -f /dev/sdG0/data qemountout",
        "mount -c /srv/qemountout /n/out",
        "mkdir -p /usr/glenda/qemount-build",
        "cd /usr/glenda/qemount-build",
        "tar xzf /n/src/*",
        "cd 9front-*",
        "bind -ac `{pwd} /",
        "cd /",
        ". /sys/lib/rootstub",
        "cd /sys/src",
        "mk nuke",
        "mk libs",
        "mk install",
        "mk clean",
        "cd /sys/src/9/pc64",
        "mk install",
        "mk clean",
        "mkdir -p /n/src9",
        "bind / /n/src9",
        "cd /sys/lib/dist",
        "mk /tmp/qemount.amd64.iso",
        "cp /tmp/qemount.amd64.iso /n/out/9front.iso",
        "echo QEMOUNT_BUILD_OK >/n/out/proof.txt",
        "unmount /n/out",
    ]:
        run(command)
finally:
    qemu.terminate(force=True)
    qemu.wait()
