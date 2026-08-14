#!/bin/sh
set -eu

case "$OUTPUT_ARCH" in
    x86_64|aarch64) ;;
    *)
        echo "Unsupported 9front architecture: $OUTPUT_ARCH" >&2
        exit 1
        ;;
esac

bootstrap=/host/build/sources/9front-11957.amd64.qcow2.gz
source=/host/build/sources/9front-11957.tar.gz
cache=$QEMOUNT_CACHE_DIR
mkdir -p "$cache"

bootstrap_image=$cache/bootstrap.qcow2
if ! qemu-img info "$bootstrap_image" >/dev/null 2>&1; then
    temporary=$cache/bootstrap.qcow2.tmp
    gzip -dc "$bootstrap" > "$temporary"
    qemu-img check -f qcow2 "$temporary"
    mv "$temporary" "$bootstrap_image"
fi

source_iso=$cache/source-qemount.iso
source_hash=$(sha256sum \
    "$source" \
    /build/plan9.ini \
    /build/plan9-arm64.ini \
    /build/qemount.rc \
    /build/qemount-mount.rc \
    /build/qemount-init.rc \
    /build/qemount-fsprobe.c \
    /build/qemount.proto \
    /build/qemount-amd64.proto \
    /build/qemount-arm64.proto \
    /build/qemount-build.rc)
source_hash=$(printf '%s\n' "$source_hash" | sha256sum | cut -d ' ' -f 1)
if [ ! -s "$source_iso" ] || [ ! -f "$source_iso.$source_hash" ]; then
    temporary=$cache/source-qemount.iso.tmp
    rm -f "$temporary"
    genisoimage -quiet -R -J -graft-points -o "$temporary" \
        "$(basename "$source")=$source" \
        qemount/plan9-amd64.ini=/build/plan9.ini \
        qemount/plan9-arm64.ini=/build/plan9-arm64.ini \
        qemount/qemount.rc=/build/qemount.rc \
        qemount/qemount-mount.rc=/build/qemount-mount.rc \
        qemount/qemount-init.rc=/build/qemount-init.rc \
        qemount/qemount-fsprobe.c=/build/qemount-fsprobe.c \
        qemount/qemount.proto=/build/qemount.proto \
        qemount/qemount-amd64.proto=/build/qemount-amd64.proto \
        qemount/qemount-arm64.proto=/build/qemount-arm64.proto \
        qemount/qemount-build.rc=/build/qemount-build.rc
    mv "$temporary" "$source_iso"
    rm -f "$cache"/source-qemount.iso.*
    : > "$source_iso.$source_hash"
fi

rm -rf "$cache"/run.*
work=$(mktemp -d "$cache/run.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM

qemu-img create -f qcow2 -F qcow2 -b "$bootstrap_image" \
    "$work/system.qcow2"
truncate -s 1536M "$work/output.fat"
mkfs.vfat -F 32 -n QEMOUNTOUT "$work/output.fat" >/dev/null

python3 /build/build.py \
    "$OUTPUT_ARCH" \
    "$work/system.qcow2" \
    "$source_iso" \
    "$work/output.fat"

test "$(mtype -i "$work/output.fat" ::proof.txt)" = QEMOUNT_BUILD_OK

for output in "$@"; do
    output_path=/host/build/$output
    mkdir -p "$(dirname "$output_path")"
    temporary=$(dirname "$output_path")/.$(basename "$output_path").tmp

    case "$output" in
        bin/qemu/${OUTPUT_PLATFORM}/qemount/9front.iso)
            mcopy -o -i "$work/output.fat" ::9front.iso "$temporary"
            ;;
        bin/qemu/${OUTPUT_PLATFORM}/qemount/9front.qcow2)
            mcopy -o -i "$work/output.fat" ::9front.qcow2 "$temporary"
            qemu-img check -f qcow2 "$temporary"
            ;;
        bin/qemu/${OUTPUT_PLATFORM}/qemount/u-boot.bin)
            cp /usr/lib/u-boot/qemu_arm64/u-boot.bin "$temporary"
            ;;
        bin/${OUTPUT_PLATFORM}/mksacfs)
            mcopy -o -i "$work/output.fat" ::mksacfs "$temporary"
            chmod 755 "$temporary"
            ;;
        *)
            echo "Unexpected output: $output" >&2
            exit 1
            ;;
    esac

    test -s "$temporary"
    case "$output" in
        bin/qemu/${OUTPUT_PLATFORM}/qemount/9front.iso|\
        bin/qemu/${OUTPUT_PLATFORM}/qemount/9front.qcow2)
            size=$(stat -c %s "$temporary")
            limit=$((16 * 1024 * 1024))
            if [ "$size" -gt "$limit" ]; then
                echo "9front appliance exceeds 16 MiB: $size bytes" >&2
                exit 1
            fi
            ;;
    esac
    mv "$temporary" "$output_path"
done
