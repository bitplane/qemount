#!/bin/sh
set -e

cd /work
tar -xf /host/build/sources/dropbear-2025.88.tar.bz2
cd dropbear-2025.88

./configure --disable-zlib

make PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp" MULTI=1 STATIC=1 -j${JOBS}

mkdir -p /host/build/bin/${ARCH}-linux-${ENV}
cp -v dropbearmulti /host/build/bin/${ARCH}-linux-${ENV}/
strip /host/build/bin/${ARCH}-linux-${ENV}/dropbearmulti || true
