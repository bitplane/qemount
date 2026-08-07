#!/bin/bash
set -euo pipefail

usage() {
    cat <<EOF
Usage: $0 <boot-image> -i <target-image> [-s <socket>] [-- extra_qemu_args]

Options:
  -i <image>    Attach the single disk image to inspect
  -s <socket>   9P serial socket path (default: /tmp/qemount-9front-9p.sock)
EOF
}

if [[ $# -lt 1 ]]; then
    usage
    exit 1
fi

BOOT_IMAGE=$1
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
if [[ ! -f "$BOOT_IMAGE" ]]; then
    echo "Boot image not found: $BOOT_IMAGE" >&2
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

COMMON_ARGS=(
    -smp 2
    -m 1024
    -display none
    -monitor none
    -no-reboot
)

case "$BOOT_IMAGE" in
    *.iso)
        QEMU=${QEMOUNT_QEMU:-qemu-system-x86_64}
        QEMU_ARGS=(
            -machine q35,accel=kvm:tcg
            -cpu max
            "${COMMON_ARGS[@]}"
            -drive "file=$BOOT_IMAGE,media=cdrom,format=raw,readonly=on"
            -drive "file=$TARGET_IMAGE,if=virtio,format=raw,snapshot=on"
            -serial stdio
            -chardev "socket,id=p9channel,path=$SOCKET_PATH,server=on,wait=off"
            -serial chardev:p9channel
        )
        ;;
    *.qcow2)
        FIRMWARE=$(dirname "$BOOT_IMAGE")/u-boot.bin
        if [[ ! -f "$FIRMWARE" ]]; then
            echo "ARM64 U-Boot firmware not found: $FIRMWARE" >&2
            exit 1
        fi
        QEMU=${QEMOUNT_QEMU:-qemu-system-aarch64}
        if [[ $(uname -m) == aarch64 && -r /dev/kvm && -w /dev/kvm ]]; then
            MACHINE=virt,gic-version=3,highmem-ecam=off,accel=kvm
            CPU=host
        else
            MACHINE=virt,gic-version=3,highmem-ecam=off,accel=tcg
            CPU=max
        fi
        QEMU_ARGS=(
            -machine "$MACHINE"
            -cpu "$CPU"
            "${COMMON_ARGS[@]}"
            -bios "$FIRMWARE"
            -drive "file=$BOOT_IMAGE,if=none,id=boot,format=qcow2,snapshot=on"
            -device virtio-blk-pci-non-transitional,drive=boot
            -drive "file=$TARGET_IMAGE,if=none,id=target,format=raw,snapshot=on"
            -device virtio-blk-pci-non-transitional,drive=target
            -chardev "socket,id=p9channel,path=$SOCKET_PATH,server=on,wait=off"
            -serial chardev:p9channel
        )
        ;;
    *)
        echo "Unsupported 9front boot image: $BOOT_IMAGE" >&2
        exit 1
        ;;
esac
QEMU_ARGS+=("${EXTRA_ARGS[@]}")

echo "9P socket: $SOCKET_PATH"
echo "  9pfuse -n 1 $SOCKET_PATH <mountpoint>"

exec "$QEMU" "${QEMU_ARGS[@]}"
