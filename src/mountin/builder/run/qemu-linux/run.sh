#!/bin/bash
set -euo pipefail

# QEMU runner script for Linux guests
# Usage: run-linux.sh <arch> <kernel> <boot_img> [options]
# Options:
#   -i <image>    Add a disk image (user's filesystem to mount)
#   -m <mode>     Guest mode (passed via kernel cmdline, default: sh)
#   -s <socket>   9P socket path (default: /tmp/9p.sock)
#   -n            Enable networking

if [ $# -lt 3 ]; then
    echo "Usage: $0 <arch> <kernel> <boot_img> [options] [-- extra_qemu_args]"
    echo "Options:"
    echo "  -i <image>    Add a disk image (user's filesystem)"
    echo "  -m <mode>     Guest mode (default: sh)"
    echo "  -s <socket>   9P socket path (default: /tmp/9p.sock)"
    echo "  -n            Enable networking"
    echo "Example: $0 x86_64 kernel boot.img -i test.ext2 -m 9p -n"
    exit 1
fi

OUTPUT_ARCH="$1"
KERNEL="$2"
BOOT_IMG="$3"
shift 3

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd -- "$SCRIPT_DIR/../../../../.." && pwd)
FIRMWARE_DIR=${MOUNTIN_QEMU_FIRMWARE:-$PROJECT_ROOT/build/bin/qemu-system/firmware}
source "$SCRIPT_DIR/../../disk/qemu/qemu-linux-arch.sh"
set_qemu_linux_arch_profile "$OUTPUT_ARCH"

# Default values
IMAGES=()
MODE="sh"
SOCKET_PATH="/tmp/9p.sock"
ENABLE_NET=""
EXTRA_ARGS=()

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i)
            IMAGES+=("$2")
            shift 2
            ;;
        -m)
            MODE="$2"
            shift 2
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

# Build QEMU command
QEMU_ARGS=(
    "${QEMU_MACHINE_ARGS[@]}"
    -L "$FIRMWARE_DIR"
    -m 128
    -kernel "$KERNEL"
    -drive "file=$BOOT_IMG,format=raw,if=virtio,readonly=on"
    -nographic
)

# Add kernel command line (mode is always passed to guest)
# root=/dev/vda = our boot.img, user disk will be vdb
QEMU_ARGS+=(-append "root=/dev/vda ro console=$QEMU_CONSOLE mode=$MODE")

# Add user's disk images (become vdb, vdc, vdd, ...)
for img in "${IMAGES[@]}"; do
    QEMU_ARGS+=(-drive "file=$img,format=raw,if=virtio")
done

# Add networking if requested
if [ -n "$ENABLE_NET" ]; then
    QEMU_ARGS+=(
        -netdev user,id=net0,hostfwd=tcp::10022-:22,hostfwd=tcp::5640-:5640
        -device virtio-net-pci,netdev=net0
    )
fi

# Clean up any existing socket and add virtio-serial for 9P communication
rm -f "$SOCKET_PATH"
QEMU_ARGS+=(
    -chardev socket,id=p9channel,path=$SOCKET_PATH,server=on,wait=off
    -device virtio-serial
    -device virtconsole,chardev=p9channel,name=9pport
)
echo "9P socket: $SOCKET_PATH"

# Add any extra arguments
QEMU_ARGS+=("${EXTRA_ARGS[@]}")

# Run QEMU
echo "Starting QEMU..."
exec "$QEMU_BIN" "${QEMU_ARGS[@]}"
