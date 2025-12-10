#!/bin/bash
set -euo pipefail

# NetBSD QEMU runner script
# Usage: run-netbsd.sh <arch> <boot-image> [options]
# Options:
#   -i <image>    Add a disk image (mounted as second drive)
#   -m <mode>     Boot mode (9p, sshd, sh)
#   -s <socket>   9P socket path (default: /tmp/9p.sock)
#   -n            Enable networking

if [ $# -lt 2 ]; then
    echo "Usage: $0 <arch> <boot-image> [options] [-- extra_qemu_args]"
    echo "Options:"
    echo "  -i <image>    Add a disk image (mounted as second drive)"
    echo "  -m <mode>     Boot mode (9p, sshd, sh) - default: sh"
    echo "  -s <socket>   9P socket path (default: /tmp/9p.sock)"
    echo "  -n            Enable networking"
    echo "Example: $0 x86_64 boot.img -i test.img -m 9p -n"
    exit 1
fi

ARCH="$1"
BOOT_IMAGE="$2"
shift 2

# Default values
IMAGE=""
MODE="sh"
SOCKET_PATH="/tmp/9p.sock"
ENABLE_NET=""
EXTRA_ARGS=()

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i)
            IMAGE="$2"
            shift 2
            ;;
        -m)
            MODE="$2"
            shift 2
            ;;
        -9p)
            MODE="9p"
            shift
            ;;
        -s)
            SOCKET_PATH="$2"
            shift 2
            ;;
        -n)
            ENABLE_NET="yes"
            shift
            ;;
        --)
            shift
            EXTRA_ARGS=("$@")
            break
            ;;
        *)
            EXTRA_ARGS+=("$1")
            shift
            ;;
    esac
done

# Map architecture to QEMU binary
case "$ARCH" in
    x86_64) QEMU_BIN="qemu-system-x86_64" ;;
    aarch64|arm64) QEMU_BIN="qemu-system-aarch64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Build QEMU command
# NetBSD boots from disk image with embedded bootloader
# The kernel has an embedded md0 ramdisk for root
QEMU_ARGS=(
    -drive "file=$BOOT_IMAGE,format=raw,if=virtio"
    -m 256
    -fw_cfg name=opt/qemount/mode,string=$MODE
)

# Add user disk image if specified (as second drive for mounting)
if [ -n "$IMAGE" ]; then
    QEMU_ARGS+=(-drive "file=$IMAGE,format=raw,if=virtio")
fi

# Add networking if requested
if [ -n "$ENABLE_NET" ]; then
    QEMU_ARGS+=(
        -netdev user,id=net0,hostfwd=tcp::10022-:22,hostfwd=tcp::5640-:5640
        -device virtio-net-pci,netdev=net0
    )
fi

# Set up console and 9P channel (same hardware config regardless of mode)
rm -f "$SOCKET_PATH"

QEMU_ARGS+=(
    -nographic
    -chardev socket,id=p9channel,path=$SOCKET_PATH,server=on,wait=off
    -device virtio-serial
    -device virtconsole,chardev=p9channel,name=9pport
)

echo "9P socket: $SOCKET_PATH"
if [ "$MODE" = "9p" ]; then
    echo "Connect with: 9pfuse $SOCKET_PATH <mountpoint>"
fi

# Add any extra arguments
QEMU_ARGS+=("${EXTRA_ARGS[@]}")

# Run QEMU
echo "Starting NetBSD QEMU..."
exec "$QEMU_BIN" "${QEMU_ARGS[@]}"
