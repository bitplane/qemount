#!/bin/sh
set -eu

OUTPUT_DIR=/host/build/bin/qemu/${ARCH}-haiku/r1beta5/system
OUTPUT_IMAGE=$OUTPUT_DIR/haiku-minimum.image
BUILD_JOBS=${JOBS:-1}

jam -q -j"$BUILD_JOBS" @minimum-raw

mkdir -p "$OUTPUT_DIR"
install -m 644 /src/haiku/generated/haiku-minimum.image "$OUTPUT_IMAGE"
