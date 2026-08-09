#!/bin/sh
set -eu

SDK_ARCHIVE=/host/build/sources/MacOSX11.3.sdk.tar.xz
SDK_HASH=$(sha256sum "$SDK_ARCHIVE" | cut -d ' ' -f 1)
SDK_CACHE=/host/build/cache/darwin/sdk/$SDK_HASH
SDK=$SDK_CACHE/MacOSX11.3.sdk
OUTPUT_DIR=/host/build/bin/${OUTPUT_ARCH}-darwin
OUTPUT=$OUTPUT_DIR/qemount-init
TARGET=x86_64-apple-macos10.13

if [ ! -d "$SDK" ]; then
    mkdir -p "$SDK_CACHE"
    tar --no-same-owner -xJf "$SDK_ARCHIVE" -C "$SDK_CACHE"
fi

mkdir -p "$OUTPUT_DIR"
clang-14 --target="$TARGET" -isysroot "$SDK" -mmacosx-version-min=10.13 \
    -Os -g0 -D_DARWIN_C_SOURCE -D__APPLE_API_UNSTABLE \
    -fuse-ld=lld -Wl,-dead_strip \
    -o "$OUTPUT" /qemount-init.c
llvm-strip-14 -S "$OUTPUT"
llvm-objdump-14 --macho --dylibs-used "$OUTPUT" \
    | grep -q '/usr/lib/libSystem.B.dylib'
