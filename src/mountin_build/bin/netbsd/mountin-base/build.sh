#!/bin/sh
set -eu

OUTPUT_DIR="/host/build/bin/${OUTPUT_ARCH}-netbsd"
SHARE_DIR="/host/build/share/${OUTPUT_ARCH}-netbsd"

mkdir -p "$OUTPUT_DIR" "$SHARE_DIR"
cp /opt/mountin/mountin-rescue "$OUTPUT_DIR/mountin-rescue"
cp /opt/mountin/devices.mtree "$SHARE_DIR/mountin-devices.mtree"
