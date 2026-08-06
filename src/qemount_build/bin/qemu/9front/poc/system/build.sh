#!/bin/sh
set -eu

test "$OUTPUT_ARCH" = x86_64

version=95ad97b98af078a1ca6a45f76725f6b693fa6795
bootstrap=/host/build/sources/9front-11957.amd64.qcow2.gz
source=/host/build/sources/9front-${version}.tar.gz
cache=/host/build/cache/9front/${BUILD_PLATFORM}/x86_64/11957-${version}
output_dir=/host/build/bin/qemu/${OUTPUT_PLATFORM}/poc/system

mkdir -p "$cache" "$output_dir"

bootstrap_image=$cache/bootstrap.qcow2
if ! qemu-img info "$bootstrap_image" >/dev/null 2>&1; then
    temporary=$cache/bootstrap.qcow2.tmp
    gzip -dc "$bootstrap" > "$temporary"
    qemu-img check -f qcow2 "$temporary"
    mv "$temporary" "$bootstrap_image"
fi

source_iso=$cache/source.iso
if [ ! -s "$source_iso" ]; then
    temporary=$cache/source.iso.tmp
    genisoimage -quiet -R -J -o "$temporary" "$source"
    mv "$temporary" "$source_iso"
fi

work=$(mktemp -d "$cache/run.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM

qemu-img create -f qcow2 -F qcow2 -b "$bootstrap_image" \
    "$work/system.qcow2"
truncate -s 1536M "$work/output.fat"
mkfs.vfat -F 32 -n QEMOUNTOUT "$work/output.fat" >/dev/null

python3 /build/build.py \
    "$work/system.qcow2" \
    "$source_iso" \
    "$work/output.fat"

test "$(mtype -i "$work/output.fat" ::proof.txt)" = QEMOUNT_BUILD_OK
temporary=$output_dir/.9front.iso.tmp
mcopy -o -i "$work/output.fat" ::9front.iso "$temporary"
test -s "$temporary"
mv "$temporary" "$output_dir/9front.iso"
