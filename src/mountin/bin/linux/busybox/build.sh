#!/bin/sh
set -e

cd /work
tar -xf /host/build/sources/busybox-1.36.1.tar.bz2
cd busybox-1.36.1

# Start with defconfig, merge our custom config
make defconfig
python3 /merge_config.py .config /busybox.config .config

# Accept defaults for any new options
yes "" | make oldconfig || true

# Build static busybox
make -j${MOUNTIN_BUILD_JOBS} CC=$CC CONFIG_STATIC=y

# Copy to output
mkdir -p /host/build/bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}
cp -v busybox /host/build/bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/
strip /host/build/bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/busybox
