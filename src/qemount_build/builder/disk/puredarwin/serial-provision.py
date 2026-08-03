#!/usr/bin/env python3

import argparse
import mmap
import os
from pathlib import Path
import socket
import subprocess
import sys
import time


BOOT_FLAGS = b"-v hid-legacy-shim=1 debug=0x08"
SERIAL_FLAGS = b"-v serial=3          debug=0x08"
PROMPT = b"bash-3.2# "
COMPLETE = b"QEMOUNT_PROVISIONED"
BYTE_INTERVAL = 0.001


def send_slow(channel: socket.socket, data: bytes) -> None:
    for byte in data:
        channel.sendall(bytes((byte,)))
        time.sleep(BYTE_INTERVAL)


def patch_boot_flags(image: Path) -> None:
    with image.open("r+b") as stream:
        with mmap.mmap(stream.fileno(), 0) as contents:
            offset = contents.find(BOOT_FLAGS)
            if offset < 0:
                raise RuntimeError("PureDarwin boot flags were not found")
            if contents.find(BOOT_FLAGS, offset + 1) >= 0:
                raise RuntimeError("PureDarwin boot flags were not unique")
            contents[offset : offset + len(BOOT_FLAGS)] = SERIAL_FLAGS
            contents.flush()


def read_until(
    channel: socket.socket,
    process: subprocess.Popen[bytes],
    needle: bytes,
    timeout: float,
) -> None:
    deadline = time.monotonic() + timeout
    received = bytearray()

    while needle not in received:
        if time.monotonic() >= deadline:
            raise TimeoutError(f"timed out waiting for {needle!r}")
        if process.poll() is not None:
            raise RuntimeError(
                f"QEMU exited with status {process.returncode} before {needle!r}"
            )

        try:
            chunk = channel.recv(4096)
        except socket.timeout:
            continue
        if not chunk:
            raise RuntimeError("PureDarwin serial channel closed")

        sys.stdout.buffer.write(chunk)
        sys.stdout.buffer.flush()
        received.extend(chunk)
        if len(received) > 65536:
            del received[:-32768]


def connect_serial(path: Path, process: subprocess.Popen[bytes]) -> socket.socket:
    deadline = time.monotonic() + 10
    while time.monotonic() < deadline:
        if process.poll() is not None:
            raise RuntimeError(f"QEMU exited with status {process.returncode}")
        try:
            channel = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            channel.connect(str(path))
            channel.settimeout(1)
            return channel
        except (FileNotFoundError, ConnectionRefusedError):
            channel.close()
            time.sleep(0.1)
    raise TimeoutError("timed out connecting to the PureDarwin serial channel")


def stop_process(process: subprocess.Popen[bytes]) -> None:
    if process.poll() is not None:
        return
    process.terminate()
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("image", type=Path)
    parser.add_argument("provision_script", type=Path)
    parser.add_argument("--patch-serial", action="store_true")
    parser.add_argument("--target", type=Path)
    parser.add_argument("--snapshot-drive", action="append", default=[], type=Path)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    image = args.image.resolve()
    provision_script = args.provision_script.read_bytes()
    serial_path = Path("/tmp/puredarwin-serial.sock")
    serial_path.unlink(missing_ok=True)
    if args.patch_serial:
        patch_boot_flags(image)

    build_arch = os.environ.get("BUILD_ARCH", "x86_64")
    qemu = f"/host/build/bin/qemu-system/{build_arch}-linux-musl/qemu-system-x86_64"
    firmware = "/host/build/bin/qemu-system/firmware"
    source_drive = f"format=raw,file={image},index=0"
    if args.target:
        source_drive += ",snapshot=on"

    command = [
        qemu,
        "-L",
        firmware,
        "-machine",
        "pc,accel=tcg",
        "-cpu",
        "Penryn",
        "-smp",
        "2",
        "-m",
        "2048",
        "-display",
        "none",
        "-monitor",
        "none",
        "-no-reboot",
        "-net",
        "none",
        "-chardev",
        f"socket,id=serial,path={serial_path},server=on,wait=off",
        "-serial",
        "chardev:serial",
        "-boot",
        "c",
        "-drive",
        source_drive,
    ]
    if args.target:
        command.extend(
            ["-drive", f"format=raw,file={args.target.resolve()},index=1"]
        )
    for index, drive in enumerate(args.snapshot_drive, start=2):
        command.extend(
            [
                "-drive",
                f"format=raw,file={drive.resolve()},snapshot=on,index={index}",
            ]
        )

    process = subprocess.Popen(command)
    try:
        with connect_serial(serial_path, process) as channel:
            read_until(channel, process, PROMPT, 180)
            send_slow(channel, b"stty -echo\n")
            read_until(channel, process, PROMPT, 10)
            send_slow(
                channel,
                b"cat > /private/tmp/qemount-provision.sh <<'QEMOUNT_EOF'\n",
            )
            send_slow(channel, provision_script)
            if not provision_script.endswith(b"\n"):
                send_slow(channel, b"\n")
            send_slow(channel, b"QEMOUNT_EOF\n")
            send_slow(channel, b"/bin/sh /private/tmp/qemount-provision.sh\n")
            read_until(channel, process, COMPLETE, 180)
            stop_process(process)
    finally:
        stop_process(process)
        serial_path.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
