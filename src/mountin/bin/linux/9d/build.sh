#!/bin/sh
set -e

cd /work

# Extract the complete release source.
mkdir -p 9d-source
tar -xf /host/build/sources/9d-0.7.1.tar.xz \
    -C 9d-source --strip-components=1

# Build the optimized static server using its pinned libixp tree.
make -C /work/9d-source \
    RELEASE_CFLAGS="-Os -DNDEBUG -DS9_PATH_MAX=1024" \
    release

# Copy to output
mkdir -p /host/build/bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}
cp -v /work/9d-source/build/9d \
    /host/build/bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/
