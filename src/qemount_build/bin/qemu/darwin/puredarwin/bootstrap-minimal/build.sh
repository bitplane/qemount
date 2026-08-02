#!/bin/sh
set -eu

BOOTSTRAP=/host/build/bin/qemu/${ARCH}-darwin/puredarwin/bootstrap/puredarwin.raw
OUTPUT_DIR=/host/build/bin/qemu/${ARCH}-darwin/puredarwin/bootstrap-minimal
WORK_IMAGE=$OUTPUT_DIR/puredarwin.work.raw
OUTPUT_TMP=$OUTPUT_DIR/puredarwin.raw.tmp
OUTPUT=$OUTPUT_DIR/puredarwin.raw

mkdir -p "$OUTPUT_DIR"
rm -f "$WORK_IMAGE" "$OUTPUT_TMP"
cp --reflink=auto --sparse=always "$BOOTSTRAP" "$WORK_IMAGE"

/serial-provision.py --patch-serial "$WORK_IMAGE" /provision.sh

qemu-img convert -f raw -O raw -S 4096 "$WORK_IMAGE" "$OUTPUT_TMP"
qemu-img info "$OUTPUT_TMP"
rm -f "$WORK_IMAGE"
mv "$OUTPUT_TMP" "$OUTPUT"
