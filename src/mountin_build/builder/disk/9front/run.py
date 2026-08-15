#!/usr/bin/env python3

import sys

import pexpect


if len(sys.argv) not in (4, 5):
    raise SystemExit(
        "usage: run-9front-fixture BOOT_ISO FIXTURE_ISO TARGET_IMAGE "
        "[--writable-fat]"
    )

boot_iso, fixture_iso, target_image = sys.argv[1:4]
writable_fat = sys.argv[4:] == ["--writable-fat"]
if sys.argv[4:] and not writable_fat:
    raise SystemExit(f"unknown option: {sys.argv[4]}")

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
        f"file={target_image},if=none,format=raw,id=mountintarget",
        "-device",
        "virtio-blk-pci,drive=mountintarget",
    ],
    encoding="utf-8",
    codec_errors="replace",
    timeout=180,
)
qemu.logfile_read = sys.stdout


def run(command: str) -> None:
    qemu.sendline(
        f"{{{command}}}; command_status=$status; "
        'if(~ $"command_status \'\') echo MOUNTIN_^COMMAND_OK; '
        'if(! ~ $"command_status \'\') echo MOUNTIN_^COMMAND_FAILED'
    )
    result = qemu.expect(
        [r"MOUNTIN_COMMAND_OK", r"MOUNTIN_COMMAND_FAILED"], timeout=180
    )
    qemu.expect(r"term% ", timeout=180)
    if result != 0:
        raise RuntimeError(f"9front command failed: {command}")


try:
    qemu.expect(r"term% ", timeout=180)
    if writable_fat:
        run("unmount /mnt/data")
        run("dossrv -f /dev/sdF0/data mountindisk")
        run("mount -c /srv/mountindisk /n/mountin")
    run("mkdir -p /n/mountin-fixture")
    run("9660srv -f /dev/sdE1/data mountinfixture")
    run("mount /srv/mountinfixture /n/mountin-fixture")
    run("rc -x /n/mountin-fixture/fixture.rc")
finally:
    qemu.terminate(force=True)
    qemu.wait()
