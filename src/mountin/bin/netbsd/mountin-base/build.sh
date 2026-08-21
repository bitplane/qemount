#!/bin/sh
set -eu

OUTPUT_DIR="/host/build/bin/${MOUNTIN_TARGET_ARCH}-netbsd"
SHARE_DIR="/host/build/share/${MOUNTIN_TARGET_ARCH}-netbsd"

mkdir -p "$OUTPUT_DIR" "$SHARE_DIR"
cp /opt/mountin/mountin-rescue "$OUTPUT_DIR/mountin-rescue"
cp /opt/mountin/mountin-fwcfg "$OUTPUT_DIR/mountin-fwcfg"
cp /opt/mountin/devices.mtree "$SHARE_DIR/mountin-devices.mtree"
