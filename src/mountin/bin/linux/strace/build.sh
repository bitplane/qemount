#!/bin/sh
set -e

cd /work
tar -xf /host/build/sources/strace-6.7.tar.xz
cd strace-6.7

# Disable -Wunterminated-string-initialization warning (new in GCC 15)
CFLAGS="-Wno-unterminated-string-initialization" LDFLAGS=-static ./configure \
    --host="$MOUNTIN_TARGET_PLATFORM" \
    --disable-mpers \
    --enable-bundled=yes

make -j${MOUNTIN_BUILD_JOBS}

mkdir -p /host/build/bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}
cp -v src/strace /host/build/bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/
"$STRIP" /host/build/bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/strace
