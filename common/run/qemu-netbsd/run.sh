#!/bin/bash
set -euo pipefail

# NetBSD QEMU runner script
# Usage: run-netbsd.sh <arch> <kernel> [options]
# Options:
#   -i <image>    Add a disk image
#   -m <mode>     Boot mode (9p, sshd, sh)
#   -s <socket>   9P socket path (default: /tmp/9p.sock)
#   -n            Enable networking

if [ $# -lt 2 ]; then
    echo "Usage: $0 <arch> <kernel> [options] [-- extra_qemu_args]"
    echo "Options:"
    echo "  -i <image>    Add a disk image"
    echo "  -m <mode>     Boot mode (9p, sshd, sh) - default: sh"
    echo "  -s <socket>   9P socket path (default: /tmp/9p.sock)"
    echo "  -n            Enable networking"
    echo "Example: $0 x86_64 netbsd -i test.img -m 9p -n"
    exit 1
fi

ARCH="$1"
KERNEL="$2"
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
# NetBSD kernel has embedded ramdisk (md0), no initrd needed
QEMU_ARGS=(
    -kernel "$KERNEL"
    -nographic
    -m 256
)

# Add kernel command line for NetBSD
# console=com0 for serial, mode= passed via environment or kernel arg
APPEND="console=com0 -s"
if [ -n "$MODE" ]; then
    APPEND="$APPEND boot.mode=$MODE"
fi
QEMU_ARGS+=(-append "$APPEND")

# Add disk image if specified
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

# Add 9P support if requested
if [ "$MODE" = "9p" ]; then
    # Clean up any existing socket
    rm -f "$SOCKET_PATH"

    QEMU_ARGS+=(
        -chardev socket,id=p9channel,path=$SOCKET_PATH,server=on,wait=off
        -device virtio-serial
        -device virtserialport,chardev=p9channel,name=9pport
    )
    echo "9P server will be available at: $SOCKET_PATH"
    echo "Connect with: 9pfuse $SOCKET_PATH <mountpoint>"
fi

# Add any extra arguments
QEMU_ARGS+=("${EXTRA_ARGS[@]}")

# Run QEMU
echo "Starting NetBSD QEMU..."
exec "$QEMU_BIN" "${QEMU_ARGS[@]}"
