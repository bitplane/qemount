#!/bin/sh
set -e

cd /work
tar -xf /host/build/sources/dropbear-2025.88.tar.bz2
cd dropbear-2025.88

./configure --disable-zlib

make PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp" MULTI=1 STATIC=1 -j${MOUNTIN_BUILD_JOBS}

mkdir -p /host/build/bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}
cp -v dropbearmulti /host/build/bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/
strip /host/build/bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/dropbearmulti || true
