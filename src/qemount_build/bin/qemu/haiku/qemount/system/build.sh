#!/bin/sh
set -eu

OUTPUT_DIR=/host/build/bin/qemu/${OUTPUT_ARCH}-haiku/qemount/system
OUTPUT_IMAGE=$OUTPUT_DIR/haiku.image
BUILD_JOBS=${JOBS:-1}
CACHE_DIR=$QEMOUNT_CACHE_DIR
INIT_DIR=/src/haiku/build/qemount/init

mkdir -p "$INIT_DIR"
install -m 755 /host/build/bin/${OUTPUT_ARCH}-haiku/qemount-init \
    "$INIT_DIR/launch_daemon"

mkdir -p "$CACHE_DIR"
if [ ! -f "$CACHE_DIR/Jamfile" ]; then
    cd "$CACHE_DIR"
    /src/haiku/configure \
        --cross-tools-prefix \
        "/toolchains/cross-tools-${OUTPUT_ARCH}/bin/${OUTPUT_ARCH}-unknown-haiku-"
fi

cd "$CACHE_DIR"

jam -q -j"$BUILD_JOBS" \
    "-sHAIKU_IMAGE_SIZE=$HAIKU_IMAGE_SIZE" \
    "-sHAIKU_REVISION=$HAIKU_REVISION" \
    @qemount-raw

mkdir -p "$OUTPUT_DIR"
install -m 644 "$CACHE_DIR/haiku-qemount.image" "$OUTPUT_IMAGE"
