#!/bin/sh
set -eu

OUTPUT_DIR=/host/build/bin/qemu/${ARCH}-haiku/qemount/system
OUTPUT_IMAGE=$OUTPUT_DIR/haiku.image
BUILD_JOBS=${JOBS:-1}

jam -q -j"$BUILD_JOBS" \
    "-sHAIKU_IMAGE_SIZE=$HAIKU_IMAGE_SIZE" \
    "-sHAIKU_REVISION=$HAIKU_REVISION" \
    @qemount-raw

mkdir -p "$OUTPUT_DIR"
install -m 644 /src/haiku/generated/haiku-qemount.image "$OUTPUT_IMAGE"
