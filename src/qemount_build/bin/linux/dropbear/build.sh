#!/bin/sh
set -e

cd /work
tar -xf /host/build/sources/dropbear-2025.88.tar.bz2
cd dropbear-2025.88

./configure --disable-zlib

make PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp" MULTI=1 STATIC=1 -j$(nproc)

mkdir -p /host/build/bin/linux-${ARCH}/dropbear
cp -v dropbearmulti /host/build/bin/linux-${ARCH}/dropbear/
strip /host/build/bin/linux-${ARCH}/dropbear/dropbearmulti || true
