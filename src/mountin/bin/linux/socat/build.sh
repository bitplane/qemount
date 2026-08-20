#!/bin/sh
set -e

cd /work
tar -xf /host/build/sources/socat-1.7.4.4.tar.gz
cd socat-1.7.4.4

LDFLAGS=-static ./configure \
    --host="$MOUNTIN_TARGET_PLATFORM" \
    --disable-openssl \
    --disable-readline
make -j${MOUNTIN_BUILD_JOBS}
"$STRIP" socat

mkdir -p /host/build/bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}
cp -v socat /host/build/bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/
