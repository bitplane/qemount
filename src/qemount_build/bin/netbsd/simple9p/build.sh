#!/bin/sh
set -e

NBARCH=$(cat /tmp/nbarch)
NBGNUTRIPLE=$(cat /tmp/nbgnutriple)
SYSROOT=/usr/obj/destdir.$NBARCH
CC="/usr/tools/bin/${NBGNUTRIPLE}--netbsd-gcc"
AR="/usr/tools/bin/${NBGNUTRIPLE}--netbsd-ar"
STRIP="/usr/tools/bin/${NBGNUTRIPLE}--netbsd-strip"

cd /work

# Extract the complete release source.
mkdir -p simple9p-source
tar -xf /host/build/sources/simple9p-0.6.2.tar.xz \
    -C simple9p-source --strip-components=1

# Build the optimized static server using its pinned libixp tree.
make -C /work/simple9p-source \
    CC="$CC" AR="$AR" STRIP="$STRIP" \
    LDFLAGS="--sysroot=$SYSROOT -static" \
    RELEASE_CFLAGS="--sysroot=$SYSROOT -Os -DNDEBUG -DS9_PATH_MAX=1024" \
    release

# Copy to output
mkdir -p /host/build/bin/${OUTPUT_ARCH}-netbsd
cp -v /work/simple9p-source/build/simple9p \
    /host/build/bin/${OUTPUT_ARCH}-netbsd/
