#!/bin/sh
set -eu

BASE=/host/build/guest/${TARGET_ARCH}-linux/base/rootfs.img
NINED=/host/build/bin/${TARGET_ARCH}-linux-${ENV}/9d
OUTPUT=/host/build/bin/qemu/${TARGET_ARCH}-linux/rootfs/rootfs.img

mkdir -p "$(dirname "$OUTPUT")"
cp "$BASE" "$OUTPUT"
debugfs -w -R "write $NINED /bin/9d" "$OUTPUT"
