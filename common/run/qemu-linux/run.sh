#!/bin/bash
set -euo pipefail

# Generic QEMU runner script

if [ $# -lt 3 ]; then
    echo "Usage: $0 <arch> <kernel> <initramfs> [extra_qemu_args...]"
    echo "Example: $0 x86_64 kernel initramfs.cpio.gz -cdrom test.iso"
    exit 1
fi

ARCH="$1"
KERNEL="$2"
INITRAMFS="$3"
shift 3

# Map architecture to QEMU binary
case "$ARCH" in
    x86_64) QEMU_BIN="qemu-system-x86_64" ;;
    aarch64|arm64) QEMU_BIN="qemu-system-aarch64" ;;
    arm) QEMU_BIN="qemu-system-arm" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Run QEMU with standard options plus any extras
exec "$QEMU_BIN" \
    -kernel "$KERNEL" \
    -initrd "$INITRAMFS" \
    -nographic \
    -append "console=ttyS0" \
    "$@"
