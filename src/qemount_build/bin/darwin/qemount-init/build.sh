#!/bin/sh
set -eu

SDK=/host/build/sdk/darwin/11.3/MacOSX11.3.sdk
OUTPUT_DIR=/host/build/bin/${OUTPUT_ARCH}-darwin
OUTPUT=$OUTPUT_DIR/qemount-init
TARGET=x86_64-apple-macos10.13

mkdir -p "$OUTPUT_DIR"
clang-14 --target="$TARGET" -isysroot "$SDK" -mmacosx-version-min=10.13 \
    -Os -g0 -D_DARWIN_C_SOURCE -D__APPLE_API_UNSTABLE \
    -fuse-ld=lld -Wl,-dead_strip \
    -o "$OUTPUT" /qemount-init.c
llvm-strip-14 -S "$OUTPUT"
llvm-objdump-14 --macho --dylibs-used "$OUTPUT" \
    | grep -q '/usr/lib/libSystem.B.dylib'
