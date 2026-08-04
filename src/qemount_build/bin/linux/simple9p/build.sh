#!/bin/sh
set -e

cd /work

# Extract the complete release source.
mkdir -p simple9p-source
tar -xf /host/build/sources/simple9p-0.6.0.tar.xz \
    -C simple9p-source --strip-components=1

# Build the optimized static server using its pinned libixp tree.
make -C /work/simple9p-source \
    CC=gcc AR=ar STRIP=strip \
    RELEASE_CFLAGS="-Os -DNDEBUG -DS9_PATH_MAX=1024" \
    release

# Copy to output
mkdir -p /host/build/bin/${OUTPUT_ARCH}-linux-${ENV}
cp -v /work/simple9p-source/build/simple9p \
    /host/build/bin/${OUTPUT_ARCH}-linux-${ENV}/
