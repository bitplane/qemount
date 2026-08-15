#!/usr/bin/env python3
import selectors
import subprocess
import sys
import time


boot, output, helper = sys.argv[1:]
command = [
    "qemu-system-x86_64",
    "-machine",
    "q35",
    "-m",
    "192",
    "-drive",
    f"file={boot},format=raw,if=virtio,readonly=on",
    "-drive",
    f"file={output},format=raw,if=virtio",
    "-drive",
    f"file={helper},format=raw,if=virtio,readonly=on",
    "-device",
    "virtio-serial-pci",
    "-chardev",
    "null,id=mountin",
    "-device",
    "virtserialport,chardev=mountin,name=mountin",
    "-fw_cfg",
    "name=opt/mountin/mode,string=sh",
    "-display",
    "none",
    "-serial",
    "stdio",
    "-monitor",
    "none",
    "-no-reboot",
]

process = subprocess.Popen(
    command,
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
    bufsize=1,
)
deadline = time.monotonic() + 180
sent = False
complete = False
selector = selectors.DefaultSelector()

assert process.stdin is not None
assert process.stdout is not None
selector.register(process.stdout, selectors.EVENT_READ)

try:
    while time.monotonic() < deadline:
        if not selector.select(timeout=1):
            if process.poll() is not None:
                break
            continue
        line = process.stdout.readline()
        if not line:
            if process.poll() is not None:
                break
            continue
        print(line, end="", flush=True)
        if not sent and "Type 'exit' to shutdown" in line:
            process.stdin.write(
                "/mnt/c/newfs_lfs -F -s 131072 /dev/rld1d && "
                "mkdir /tmp/lfs && "
                "mount -t lfs /dev/ld1d /tmp/lfs && "
                "cp -Rp /mnt/c/TestData/. /tmp/lfs/ && "
                "sync && "
                "umount /tmp/lfs && "
                "mount -t lfs /dev/ld1d /tmp/lfs && "
                "test \"$(cat /tmp/lfs/basic/hello.txt)\" = \"Hello, world!\" && "
                "echo 'LFS fixture complete'\n"
                "exit\n"
            )
            process.stdin.flush()
            sent = True
        if line.strip() == "LFS fixture complete":
            complete = True
    if not complete:
        raise RuntimeError("NetBSD did not complete the LFS fixture")
finally:
    selector.close()
    if process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
