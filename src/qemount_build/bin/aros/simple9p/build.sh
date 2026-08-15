#!/bin/sh
set -eu

CC=/opt/aros-toolchain/i386-aros-gcc
AR=/opt/aros-toolchain/i386-aros-ar
STRIP=/opt/aros-toolchain/i386-aros-strip
SDK=/opt/aros-toolbox/bin/pc-i386-tiny/AROS/Developer
SIMPLE9P_SOURCE=/work/simple9p-source
OUTPUT_DIR=/host/build/bin/${OUTPUT_ARCH}-aros

rm -rf "$SIMPLE9P_SOURCE"
mkdir -p "$SIMPLE9P_SOURCE" "$OUTPUT_DIR"
tar -xf /host/build/sources/simple9p-0.6.3.tar.xz \
    -C "$SIMPLE9P_SOURCE" --strip-components=1

make -C "$SIMPLE9P_SOURCE" release \
    PLATFORM=amiga NETWORK=0 STATIC=0 THREAD_LIBS= \
    CC="$CC --sysroot=$SDK" AR="$AR" STRIP="$STRIP --strip-unneeded -R.comment" \
    API_CPPFLAGS=-D_POSIX_C_SOURCE=200809L \
    RELEASE_CFLAGS="-Os -fno-common -fno-asynchronous-unwind-tables -fno-unwind-tables -DS9_PATH_MAX=1024"

cp "$SIMPLE9P_SOURCE/build/simple9p" "$OUTPUT_DIR/simple9p"
