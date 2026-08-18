#!/bin/sh
set -eu

OUTPUT_DIR=/host/build/guest/${MOUNTIN_TARGET_ARCH}-haiku/r1-beta6-hrev59919+1
OUTPUT_IMAGE=$OUTPUT_DIR/haiku.image
MOUNTIN_BUILD_JOBS=${MOUNTIN_BUILD_JOBS:-1}
CACHE_DIR=/src/haiku/generated

# The compiler toolbox defaults ordinary consumers to the Haiku target. Jam's
# configured build graph owns compiler selection for both host and target work.
unset CC AR STRIP READELF

cd "$CACHE_DIR"

jam -q -j"$MOUNTIN_BUILD_JOBS" \
    "-sHAIKU_IMAGE_SIZE=$MOUNTIN_HAIKU_IMAGE_SIZE" \
    "-sHAIKU_REVISION=$MOUNTIN_HAIKU_REVISION" \
    @mountin-raw

mkdir -p "$OUTPUT_DIR"
install -m 644 "$CACHE_DIR/haiku-mountin.image" "$OUTPUT_IMAGE"
