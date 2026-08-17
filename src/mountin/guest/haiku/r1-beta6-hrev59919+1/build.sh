#!/bin/sh
set -eu

OUTPUT_DIR=/host/build/guest/${OUTPUT_ARCH}-haiku/r1-beta6-hrev59919+1
OUTPUT_IMAGE=$OUTPUT_DIR/haiku.image
BUILD_JOBS=${JOBS:-1}
CACHE_DIR=/src/haiku/generated

# The compiler toolbox defaults ordinary consumers to the Haiku target. Jam's
# configured build graph owns compiler selection for both host and target work.
unset CC AR STRIP READELF

cd "$CACHE_DIR"

jam -q -j"$BUILD_JOBS" \
    "-sHAIKU_IMAGE_SIZE=$HAIKU_IMAGE_SIZE" \
    "-sHAIKU_REVISION=$HAIKU_REVISION" \
    @mountin-raw

mkdir -p "$OUTPUT_DIR"
install -m 644 "$CACHE_DIR/haiku-mountin.image" "$OUTPUT_IMAGE"
