#!/bin/bash
set -euo pipefail

usage() {
    cat <<EOF
Usage: $0 <arch> <boot-image> -i <target-image> [-t <media>] [-s <socket>] [-- extra_qemu_args]

Options:
  -i <image>    Attach the single filesystem image to inspect
  -t <media>    Target media: disk or cdrom (default: disk)
  -s <socket>   9P serial socket path (default: /tmp/mountin-haiku-9p.sock)
EOF
}

if [[ $# -lt 2 ]]; then
    usage
    exit 1
fi

MOUNTIN_TARGET_ARCH=$1
BOOT_IMAGE=$2
shift 2

TARGET_IMAGE=
TARGET_MEDIA=disk
SOCKET_PATH=/tmp/mountin-haiku-9p.sock
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i)
            if [[ $# -lt 2 ]]; then
                echo "Missing value for -i" >&2
                exit 1
            fi
            if [[ -n "$TARGET_IMAGE" ]]; then
                echo "The Haiku reference runner accepts exactly one target image" >&2
                exit 1
            fi
            TARGET_IMAGE=$2
            shift 2
            ;;
        -t)
            if [[ $# -lt 2 ]]; then
                echo "Missing value for -t" >&2
                exit 1
            fi
            TARGET_MEDIA=$2
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
if [[ "$TARGET_MEDIA" != disk && "$TARGET_MEDIA" != cdrom ]]; then
    echo "Invalid target media: $TARGET_MEDIA" >&2
    exit 1
fi
if [[ "$SOCKET_PATH" == / || -d "$SOCKET_PATH" ]]; then
    echo "Invalid socket path: $SOCKET_PATH" >&2
    exit 1
fi

rm -f "$SOCKET_PATH"

COMMON_ARGS=(-smp 2 -m 1024 -display none -monitor none -no-reboot)
case "$MOUNTIN_TARGET_ARCH" in
    x86_64)
        QEMU=${MOUNTIN_QEMU:-qemu-system-x86_64}
        QEMU_ARGS=(
            -machine pc,accel=tcg
            -cpu qemu64
            "${COMMON_ARGS[@]}"
            -drive "file=$BOOT_IMAGE,format=raw,if=ide,index=0,snapshot=on"
            -serial stdio
            -chardev "socket,id=p9channel,path=$SOCKET_PATH,server=on,wait=off"
            -serial chardev:p9channel
        )
        if [[ "$TARGET_MEDIA" == cdrom ]]; then
            QEMU_ARGS+=(
                -drive "file=$TARGET_IMAGE,format=raw,if=ide,index=1,media=cdrom,readonly=on"
            )
        else
            QEMU_ARGS+=(
                -drive "file=$TARGET_IMAGE,format=raw,if=ide,index=1"
            )
        fi
        ;;
    aarch64)
        SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
        PROJECT_ROOT=$(cd -- "$SCRIPT_DIR/../../../../.." && pwd)
        FIRMWARE=${MOUNTIN_HAIKU_FIRMWARE:-$PROJECT_ROOT/build/bin/qemu-system/firmware/edk2-aarch64-code.fd}
        if [[ ! -f "$FIRMWARE" ]]; then
            echo "ARM64 UEFI firmware not found: $FIRMWARE" >&2
            exit 1
        fi
        QEMU=${MOUNTIN_QEMU:-qemu-system-aarch64}
        if [[ $(uname -m) == aarch64 && -r /dev/kvm && -w /dev/kvm ]]; then
            MACHINE=virt,accel=kvm
            CPU=host
        else
            MACHINE=virt,accel=tcg
            CPU=cortex-a76
        fi
        QEMU_ARGS=(
            -machine "$MACHINE"
            -cpu "$CPU"
            "${COMMON_ARGS[@]}"
            -bios "$FIRMWARE"
            -nodefaults
            -serial stdio
            -device ramfb
            -device qemu-xhci,id=usb
            -drive "file=$BOOT_IMAGE,format=raw,if=none,id=boot,snapshot=on"
            -device usb-storage,bus=usb.0,drive=boot
            -device pci-ohci,id=serialusb
            -chardev "socket,id=p9channel,path=$SOCKET_PATH,server=on,wait=off"
            -device usb-serial,bus=serialusb.0,chardev=p9channel,always-plugged=on
        )
        if [[ "$TARGET_MEDIA" == cdrom ]]; then
            QEMU_ARGS+=(
                -drive "file=$TARGET_IMAGE,format=raw,if=none,id=target,media=cdrom,readonly=on"
            )
        else
            QEMU_ARGS+=(
                -drive "file=$TARGET_IMAGE,format=raw,if=none,id=target"
            )
        fi
        QEMU_ARGS+=(-device usb-storage,bus=usb.0,drive=target)
        ;;
    *)
        echo "Unsupported Haiku architecture: $MOUNTIN_TARGET_ARCH" >&2
        exit 1
        ;;
esac
QEMU_ARGS+=("${EXTRA_ARGS[@]}")

echo "9P socket: $SOCKET_PATH"
echo "Connect with: 9pfuse -n 1 $SOCKET_PATH <mountpoint>"

exec "$QEMU" "${QEMU_ARGS[@]}"
