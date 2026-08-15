#!/bin/sh
set -eu

OUTPUT_DIR=/host/build/bin/${OUTPUT_ARCH}-haiku
OUTPUT=$OUTPUT_DIR/qemount-init

mkdir -p "$OUTPUT_DIR"
"$CC" \
    -Os -g0 -D_XOPEN_SOURCE=600 -static-libgcc \
    -o "$OUTPUT" /qemount-init.c
"$STRIP" --strip-unneeded "$OUTPUT"

"$READELF" -d "$OUTPUT" \
    | grep -q "Shared library: \\[libroot.so\\]"
if "$READELF" -d "$OUTPUT" \
        | grep -q "Shared library: \\[libgcc_s.so.1\\]"; then
    echo "qemount init unexpectedly links shared libgcc" >&2
    exit 1
fi
