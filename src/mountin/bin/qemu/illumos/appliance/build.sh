#!/bin/sh
set -eu

test "$TARGET_ARCH" = x86_64

system=/host/build/guest/${TARGET_PLATFORM}/2026-08-13/system
staging=/work/root
output_base=/host/build/bin/qemu/${TARGET_PLATFORM}/2026-08-13
output=$output_base/rootfs.iso

rm -rf "$staging"
mkdir -p \
    "$staging/dev" \
    "$staging/devices" \
    "$staging/etc/dfs" \
    "$staging/etc/svc/volatile" \
    "$staging/kernel/amd64" \
    "$staging/lib" \
    "$staging/mnt" \
    "$staging/platform/i86pc/kernel/amd64" \
    "$staging/proc" \
    "$staging/sbin" \
    "$staging/system/boot" \
    "$staging/system/contract" \
    "$staging/system/object"
cp -a "$system/root/." "$staging/"
install -m 0755 /host/build/bin/${TARGET_PLATFORM}/mountin-bootstrap \
    "$staging/sbin/init"
install -m 0755 /host/build/bin/${TARGET_PLATFORM}/mountin-init \
    "$staging/sbin/mountin-init"
install -m 0755 /host/build/bin/${TARGET_PLATFORM}/9d \
    "$staging/sbin/9d"

mkdir -p "${output%/*}"
find "$staging" -exec touch -h -d @0 {} +
xorriso -as mkisofs \
    -quiet \
    -graft-points \
    -d \
    -l \
    -r \
    -D \
    -J \
    -N \
    -relaxed-filenames \
    -o "$output.tmp" "$staging"
mv "$output.tmp" "$output"

kernel=$output_base/kernel
mkdir -p "${kernel%/*}"
install -m 0644 "$system/kernel" "$kernel"
