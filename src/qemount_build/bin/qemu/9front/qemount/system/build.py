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
        "tar xzf /n/src/9front-*.tar.gz",
        "cd 9front-*",
        "bind -ac `{pwd} /",
        "cp /n/src/qemount/plan9.ini /cfg/plan9.ini",
        "cp /n/src/qemount/qemount.rc /rc/bin/qemount",
        "cp /n/src/qemount/qemount-init.rc /rc/bin/qemount-init",
        "chmod 775 /rc/bin/qemount /rc/bin/qemount-init",
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
        "mkdir -p /n/verify",
        "9660srv -f /tmp/qemount.amd64.iso qemountverify",
        "mount /srv/qemountverify /n/verify",
        "cmp /n/src/qemount/plan9.ini /n/verify/cfg/plan9.ini",
        "cmp /n/src/qemount/qemount.rc /n/verify/rc/bin/qemount",
        "cmp /n/src/qemount/qemount-init.rc /n/verify/rc/bin/qemount-init",
        "test -x /n/verify/rc/bin/qemount",
        "test -x /n/verify/rc/bin/qemount-init",
        "unmount /n/verify",
        "cp /tmp/qemount.amd64.iso /n/out/9front.iso",
        "echo QEMOUNT_BUILD_OK >/n/out/proof.txt",
        "unmount /n/out",
    ]:
        run(command)
finally:
    qemu.terminate(force=True)
    qemu.wait()
