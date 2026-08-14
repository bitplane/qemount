#!/bin/sh
set -eu

test "$OUTPUT_ARCH" = x86_64

base=/host/build/bin/qemu/${OUTPUT_PLATFORM}/illumos/qemount
output=$base/system
kernel=$output/xplatform/i86pc/kernel/amd64/unix

rm -rf "$output"
mkdir -p "${kernel%/*}"
install -m 0644 "$base/boot/xplatform/i86pc/kernel/amd64/unix" \
    "$kernel"
install -m 0644 "$base/rootfs.iso" "$output/rootfs.iso"
