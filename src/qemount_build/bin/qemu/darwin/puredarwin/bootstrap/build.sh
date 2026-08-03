#!/bin/sh
set -eu

SOURCE=/host/build/sources/puredarwin-17.4.vmdk.xz
OUTPUT_DIR=/host/build/bin/qemu/${OUTPUT_ARCH}-darwin/puredarwin/bootstrap
VMDK_TMP=$OUTPUT_DIR/puredarwin.vmdk.tmp
OUTPUT_TMP=$OUTPUT_DIR/puredarwin.raw.tmp
OUTPUT=$OUTPUT_DIR/puredarwin.raw

mkdir -p "$OUTPUT_DIR"
rm -f "$VMDK_TMP" "$OUTPUT_TMP"
xz -dc "$SOURCE" > "$VMDK_TMP"
qemu-img check "$VMDK_TMP"
qemu-img convert -f vmdk -O raw "$VMDK_TMP" "$OUTPUT_TMP"
qemu-img info "$OUTPUT_TMP"
rm -f "$VMDK_TMP"
mv "$OUTPUT_TMP" "$OUTPUT"
