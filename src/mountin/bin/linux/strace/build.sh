#!/bin/sh
set -e

cd /work
tar -xf /host/build/sources/strace-6.7.tar.xz
cd strace-6.7

# Disable -Wunterminated-string-initialization warning (new in GCC 15)
CFLAGS="-Wno-unterminated-string-initialization" ./configure \
    --enable-static \
    --disable-shared \
    --disable-mpers \
    --enable-bundled=yes

make -j${BUILD_JOBS}

mkdir -p /host/build/bin/${TARGET_ARCH}-linux-${ENV}
cp -v src/strace /host/build/bin/${TARGET_ARCH}-linux-${ENV}/
strip /host/build/bin/${TARGET_ARCH}-linux-${ENV}/strace || true
