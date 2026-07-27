#!/bin/sh
set -eu

BASE_ISO=/host/build/bin/qemu/${ARCH}-aros/system/aros.iso
SIMPLE9P=/host/build/bin/${ARCH}-aros/simple9p
OUTPUT_DIR=/host/build/bin/qemu/${ARCH}-aros/boot
OUTPUT_TMP=$OUTPUT_DIR/aros.iso.tmp

mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_TMP"
xorriso \
    -indev "$BASE_ISO" \
    -outdev "$OUTPUT_TMP" \
    -boot_image any replay \
    -map "$SIMPLE9P" /C/simple9p \
    -map /grub.cfg /boot/grub/grub.cfg \
    -map /User-Startup /S/User-Startup \
    -commit
mv "$OUTPUT_TMP" "$OUTPUT_DIR/aros.iso"
