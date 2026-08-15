#!/bin/sh
set -eu

OUTPUT_DIR=/host/build/bin/qemu/${OUTPUT_ARCH}-haiku/r1-beta6-hrev59919+1/base
OUTPUT_IMAGE=$OUTPUT_DIR/haiku.image
BUILD_JOBS=${JOBS:-1}
CACHE_DIR=/src/haiku/generated
INIT_DIR=/src/haiku/build/qemount/init

# The compiler toolbox defaults ordinary consumers to the Haiku target. Jam's
# configured build graph owns compiler selection for both host and target work.
unset CC AR STRIP READELF

mkdir -p "$INIT_DIR"
install -m 755 /host/build/bin/${OUTPUT_ARCH}-haiku/qemount-init \
    "$INIT_DIR/launch_daemon"

cd "$CACHE_DIR"

jam -q -j"$BUILD_JOBS" \
    "-sHAIKU_IMAGE_SIZE=$HAIKU_IMAGE_SIZE" \
    "-sHAIKU_REVISION=$HAIKU_REVISION" \
    @qemount-raw

mkdir -p "$OUTPUT_DIR"
install -m 644 "$CACHE_DIR/haiku-qemount.image" "$OUTPUT_IMAGE"
