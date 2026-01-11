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

make -j${JOBS}

mkdir -p /host/build/bin/linux-${ARCH}/strace
cp -v src/strace /host/build/bin/linux-${ARCH}/strace/
strip /host/build/bin/linux-${ARCH}/strace/strace || true
