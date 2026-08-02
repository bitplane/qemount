#!/bin/sh
set -eu

SOURCE=/host/build/bin/qemu/${ARCH}-darwin/puredarwin/bootstrap-minimal/puredarwin.raw
SIMPLE9P=/host/build/bin/${ARCH}-darwin/simple9p
STREAM64=/host/build/bin/${ARCH}-darwin/stream64
OUTPUT_DIR=/host/build/bin/qemu/${ARCH}-darwin/puredarwin/appliance
WORK_IMAGE=$OUTPUT_DIR/puredarwin.work.raw
PAYLOAD_IMAGE=$OUTPUT_DIR/payload.hfs
OUTPUT_TMP=$OUTPUT_DIR/puredarwin.raw.tmp
OUTPUT=$OUTPUT_DIR/puredarwin.raw

mkdir -p "$OUTPUT_DIR"
rm -f "$WORK_IMAGE" "$PAYLOAD_IMAGE" "$OUTPUT_TMP"
truncate -s "$PUREDARWIN_IMAGE_SIZE" "$WORK_IMAGE"
parted -s "$WORK_IMAGE" \
    mklabel msdos \
    mkpart primary hfs+ 1MiB 100% \
    set 1 boot on

truncate -s 20M "$PAYLOAD_IMAGE"
hformat -l QEMOUNT_PAYLOAD "$PAYLOAD_IMAGE"
hmount "$PAYLOAD_IMAGE"
hcopy "$SIMPLE9P" :simple9p
hcopy "$STREAM64" :stream64
humount

/serial-provision.py \
    --target "$WORK_IMAGE" \
    --snapshot-drive "$PAYLOAD_IMAGE" \
    "$SOURCE" /populate.sh

dd if="$SOURCE" of="$WORK_IMAGE" bs=446 count=1 conv=notrunc status=none
dd if="$SOURCE" of="$WORK_IMAGE" \
    bs=512 skip=1 seek=2048 count=2 conv=notrunc status=none

qemu-img convert -f raw -O raw -S 4096 "$WORK_IMAGE" "$OUTPUT_TMP"
qemu-img info "$OUTPUT_TMP"
rm -f "$WORK_IMAGE" "$PAYLOAD_IMAGE"
mv "$OUTPUT_TMP" "$OUTPUT"
