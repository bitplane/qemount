#!/bin/sh
set -eu

SDK=/host/build/sdk/darwin/11.3/MacOSX11.3.sdk
SOURCE=/work/simple9p
OBJECTS=/work/objects
OUTPUT_DIR=/host/build/bin/${OUTPUT_ARCH}-darwin
TARGET=x86_64-apple-macos10.13

rm -rf "$SOURCE" "$OBJECTS"
mkdir -p "$SOURCE" "$OBJECTS" "$OUTPUT_DIR"
tar -xf /host/build/sources/simple9p-0.6.3.tar.xz \
    -C "$SOURCE" --strip-components=1

CC="clang-14 --target=$TARGET -isysroot $SDK -mmacosx-version-min=10.13"
make -C "$SOURCE" release \
    NETWORK=0 STATIC=0 \
    CC="$CC" AR=llvm-ar-14 STRIP="llvm-strip-14 -S" \
    API_CPPFLAGS=-D_XOPEN_SOURCE=600 \
    RELEASE_CFLAGS="-Os -g0 -DNDEBUG -DS9_PATH_MAX=1024" \
    LDFLAGS="-fuse-ld=lld -Wl,-dead_strip"

llvm-objdump-14 --macho --private-headers "$SOURCE/build/simple9p" \
    | grep -Eq 'LC_(BUILD_VERSION|VERSION_MIN_MACOSX)'
install -m 755 "$SOURCE/build/simple9p" "$OUTPUT_DIR/simple9p"

$CC -Os -g0 -fuse-ld=lld -Wl,-dead_strip -o "$OBJECTS/stream64" \
    /stream64.c -lpthread
llvm-strip-14 -S "$OBJECTS/stream64"
install -m 755 "$OBJECTS/stream64" "$OUTPUT_DIR/stream64"
