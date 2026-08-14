#!/bin/sh
set -eu

OUTPUT_DIR=/host/build/bin/${OUTPUT_ARCH}-haiku
TOOL_PREFIX=/toolchains/cross-tools-${OUTPUT_ARCH}/bin/${OUTPUT_ARCH}-unknown-haiku-
SYSROOT=/opt/haiku-sysroot
OUTPUT=$OUTPUT_DIR/qemount-init

mkdir -p "$OUTPUT_DIR"
"${TOOL_PREFIX}gcc" --sysroot="$SYSROOT" \
    -Os -g0 -D_XOPEN_SOURCE=600 -static-libgcc \
    -o "$OUTPUT" /qemount-init.c
"${TOOL_PREFIX}strip" --strip-unneeded "$OUTPUT"

"${TOOL_PREFIX}readelf" -d "$OUTPUT" \
    | grep -q "Shared library: \\[libroot.so\\]"
if "${TOOL_PREFIX}readelf" -d "$OUTPUT" \
        | grep -q "Shared library: \\[libgcc_s.so.1\\]"; then
    echo "qemount init unexpectedly links shared libgcc" >&2
    exit 1
fi
