#!/bin/sh
set -eu

BASE=/host/build/guest/${OUTPUT_ARCH}-linux/base/rootfs.img
NINED=/host/build/bin/${OUTPUT_ARCH}-linux-${ENV}/9d
OUTPUT=/host/build/bin/qemu/${OUTPUT_ARCH}-linux/rootfs/rootfs.img

mkdir -p "$(dirname "$OUTPUT")"
cp "$BASE" "$OUTPUT"
debugfs -w -R "write $NINED /bin/9d" "$OUTPUT"
