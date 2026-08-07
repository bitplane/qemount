#!/bin/bash
set -euo pipefail

usage() {
    cat <<EOF
Usage: $0 <boot-iso> -i <target-image> [-s <socket>] [-- extra_qemu_args]

Options:
  -i <image>    Attach the single disk image to inspect
  -s <socket>   9P serial socket path (default: /tmp/qemount-9front-9p.sock)
EOF
}

if [[ $# -lt 1 ]]; then
    usage
    exit 1
fi

BOOT_ISO=$1
shift

TARGET_IMAGE=
SOCKET_PATH=/tmp/qemount-9front-9p.sock
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i)
            if [[ $# -lt 2 ]]; then
                echo "Missing value for -i" >&2
                exit 1
            fi
            if [[ -n "$TARGET_IMAGE" ]]; then
                echo "The 9front reference runner accepts exactly one target image" >&2
                exit 1
            fi
            TARGET_IMAGE=$2
            shift 2
            ;;
        -s)
            if [[ $# -lt 2 ]]; then
                echo "Missing value for -s" >&2
                exit 1
            fi
            SOCKET_PATH=$2
            shift 2
            ;;
        --)
            shift
            EXTRA_ARGS=("$@")
            break
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ -z "$TARGET_IMAGE" ]]; then
    echo "A target image is required" >&2
    usage >&2
    exit 1
fi
if [[ ! -f "$BOOT_ISO" ]]; then
    echo "Boot ISO not found: $BOOT_ISO" >&2
    exit 1
fi
if [[ ! -f "$TARGET_IMAGE" ]]; then
    echo "Target image not found: $TARGET_IMAGE" >&2
    exit 1
fi
if [[ "$SOCKET_PATH" == / || -d "$SOCKET_PATH" ]]; then
    echo "Invalid socket path: $SOCKET_PATH" >&2
    exit 1
fi

rm -f "$SOCKET_PATH"

QEMU_ARGS=(
    -machine q35,accel=kvm:tcg
    -cpu max
    -smp 2
    -m 1024
    -display none
    -monitor none
    -no-reboot
    -drive "file=$BOOT_ISO,media=cdrom,format=raw,readonly=on"
    -drive "file=$TARGET_IMAGE,if=virtio,format=raw,snapshot=on"
    -serial stdio
    -chardev "socket,id=p9channel,path=$SOCKET_PATH,server=on,wait=off"
    -serial chardev:p9channel
)
QEMU_ARGS+=("${EXTRA_ARGS[@]}")

echo "9P socket: $SOCKET_PATH"
echo "After the guest prints 'term%', connect with:"
echo "  9pfuse -n 1 $SOCKET_PATH <mountpoint>"

exec "${QEMOUNT_QEMU:-qemu-system-x86_64}" "${QEMU_ARGS[@]}"
