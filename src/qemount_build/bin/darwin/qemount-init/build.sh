#!/bin/sh
set -eu

OUTPUT_DIR=/host/build/bin/${OUTPUT_ARCH}-darwin
OUTPUT=$OUTPUT_DIR/qemount-init

mkdir -p "$OUTPUT_DIR"
"$CC" \
    -Os -g0 -D_DARWIN_C_SOURCE -D__APPLE_API_UNSTABLE \
    -Wl,-dead_strip \
    -o "$OUTPUT" /qemount-init.c
"$STRIP" -S "$OUTPUT"
"$OBJDUMP" --macho --dylibs-used "$OUTPUT" \
    | grep -q '/usr/lib/libSystem.B.dylib'
