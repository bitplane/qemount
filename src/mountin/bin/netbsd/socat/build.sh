#!/bin/sh
set -e

NBGNUTRIPLE=$(cat /tmp/nbgnutriple)

cd /work
tar -xf /host/build/sources/socat-1.7.4.4.tar.gz
cd socat-1.7.4.4

LDFLAGS="-static" \
./configure \
    --host=${NBGNUTRIPLE}--netbsd \
    --disable-openssl \
    --disable-readline

make -j${BUILD_JOBS}
$STRIP socat || true

mkdir -p /host/build/bin/${TARGET_ARCH}-netbsd
cp -v socat /host/build/bin/${TARGET_ARCH}-netbsd/
