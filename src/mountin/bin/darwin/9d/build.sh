#!/bin/sh
set -eu

SOURCE=/work/9d
OBJECTS=/work/objects
OUTPUT_DIR=/host/build/bin/${OUTPUT_ARCH}-darwin

rm -rf "$SOURCE" "$OBJECTS"
mkdir -p "$SOURCE" "$OBJECTS" "$OUTPUT_DIR"
tar -xf /host/build/sources/9d-0.7.0.tar.xz \
    -C "$SOURCE" --strip-components=1

make -C "$SOURCE" release \
    NETWORK=0 STATIC=0 \
    THREAD_LIBS= \
    STRIP="$STRIP -S" \
    API_CPPFLAGS=-D_XOPEN_SOURCE=600 \
    RELEASE_CFLAGS="-Os -g0 -DNDEBUG -DS9_PATH_MAX=1024" \
    LDFLAGS="-Wl,-dead_strip"

"$OBJDUMP" --macho --private-headers "$SOURCE/build/9d" \
    | grep -Eq 'LC_(BUILD_VERSION|VERSION_MIN_MACOSX)'
install -m 755 "$SOURCE/build/9d" "$OUTPUT_DIR/9d"

"$CC" -Os -g0 -Wl,-dead_strip -o "$OBJECTS/stream64" \
    /stream64.c
"$STRIP" -S "$OBJECTS/stream64"
install -m 755 "$OBJECTS/stream64" "$OUTPUT_DIR/stream64"
