#!/bin/sh
set -e

NBARCH=$(cat /tmp/nbarch)
NBGNUTRIPLE=$(cat /tmp/nbgnutriple)
SYSROOT=/usr/obj/destdir.$NBARCH
CC="/usr/tools/bin/${NBGNUTRIPLE}--netbsd-gcc"
STRIP="/usr/tools/bin/${NBGNUTRIPLE}--netbsd-strip"

cd /work
tar -xf /host/build/sources/socat-1.7.4.4.tar.gz
cd socat-1.7.4.4

CFLAGS="--sysroot=$SYSROOT" \
LDFLAGS="--sysroot=$SYSROOT -static" \
./configure \
    --host=${NBGNUTRIPLE}--netbsd \
    CC="$CC" \
    --disable-openssl \
    --disable-readline

make -j${JOBS}
$STRIP socat || true

mkdir -p /host/build/bin/netbsd-${ARCH}/socat
cp -v socat /host/build/bin/netbsd-${ARCH}/socat/
