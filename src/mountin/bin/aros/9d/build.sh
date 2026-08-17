#!/bin/sh
set -eu

NINED_SOURCE=/work/9d-source
OUTPUT_DIR=/host/build/bin/${OUTPUT_ARCH}-aros

rm -rf "$NINED_SOURCE"
mkdir -p "$NINED_SOURCE" "$OUTPUT_DIR"
tar -xf /host/build/sources/9d-0.7.1.tar.xz \
    -C "$NINED_SOURCE" --strip-components=1

make -C "$NINED_SOURCE" release \
    PLATFORM=amiga NETWORK=0 STATIC=0 THREAD_LIBS= \
    STRIP="$STRIP --strip-unneeded -R.comment" \
    API_CPPFLAGS=-D_POSIX_C_SOURCE=200809L \
    RELEASE_CFLAGS="-Os -fno-common -fno-asynchronous-unwind-tables -fno-unwind-tables -DS9_PATH_MAX=1024"

cp "$NINED_SOURCE/build/9d" "$OUTPUT_DIR/9d"
