#!/bin/sh
set -eu

OUTPUT_DIR="/host/build/bin/${OUTPUT_ARCH}-netbsd"
SHARE_DIR="/host/build/share/${OUTPUT_ARCH}-netbsd"

mkdir -p "$OUTPUT_DIR" "$SHARE_DIR"
cp /opt/qemount/qemount-rescue "$OUTPUT_DIR/qemount-rescue"
cp /opt/qemount/devices.mtree "$SHARE_DIR/qemount-devices.mtree"
