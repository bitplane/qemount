#!/bin/sh
set -eu

BASE=/host/build/guest/${MOUNTIN_TARGET_ARCH}-linux/base/rootfs.img
NINED=/host/build/bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/9d
OUTPUT=/host/build/bin/qemu/${MOUNTIN_TARGET_ARCH}-linux/rootfs/rootfs.img

mkdir -p "$(dirname "$OUTPUT")"
cp "$BASE" "$OUTPUT"
debugfs -w -R "write $NINED /bin/9d" "$OUTPUT"
