#!/usr/bin/env python3

import sys

import pexpect


if len(sys.argv) != 4:
    raise SystemExit("usage: run-9front-fixture BOOT_ISO FIXTURE_ISO TARGET_IMAGE")

boot_iso, fixture_iso, target_image = sys.argv[1:]

qemu = pexpect.spawn(
    "qemu-system-x86_64",
    [
        "-nodefaults",
        "-machine",
        "q35,accel=kvm:tcg",
        "-cpu",
        "max",
        "-m",
        "512",
        "-smp",
        "2",
        "-display",
        "none",
        "-monitor",
        "none",
        "-serial",
        "stdio",
        "-no-reboot",
        "-boot",
        "order=d",
        "-drive",
        f"file={boot_iso},media=cdrom,format=raw,readonly=on",
        "-drive",
        f"file={fixture_iso},media=cdrom,format=raw,readonly=on",
        "-drive",
        f"file={target_image},if=none,format=raw,id=qemounttarget",
        "-device",
        "virtio-blk-pci,drive=qemounttarget",
    ],
    encoding="utf-8",
    codec_errors="replace",
    timeout=180,
)
qemu.logfile_read = sys.stdout


def run(command: str) -> None:
    qemu.sendline(
        f"{{{command}}}; command_status=$status; "
        'if(~ $"command_status \'\') echo QEMOUNT_^COMMAND_OK; '
        'if(! ~ $"command_status \'\') echo QEMOUNT_^COMMAND_FAILED'
    )
    result = qemu.expect(
        [r"QEMOUNT_COMMAND_OK", r"QEMOUNT_COMMAND_FAILED"], timeout=180
    )
    qemu.expect(r"term% ", timeout=180)
    if result != 0:
        raise RuntimeError(f"9front command failed: {command}")


try:
    qemu.expect(r"term% ", timeout=180)
    qemu.sendline(
        "unmount /n/qemount >[2=]; "
        "mount -c /srv/qemountdisk /n/qemount >[2=]"
    )
    qemu.expect(r"term% ", timeout=180)
    run("mkdir -p /n/qemount-fixture")
    run("9660srv -f /dev/sdE1/data qemountfixture")
    run("mount /srv/qemountfixture /n/qemount-fixture")
    run("rc -x /n/qemount-fixture/fixture.rc")
finally:
    qemu.terminate(force=True)
    qemu.wait()
