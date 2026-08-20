#!/bin/sh
set -e

cd /work
tar -xf /host/build/sources/busybox-1.36.1.tar.bz2
cd busybox-1.36.1

# Start with defconfig, merge our custom config
make ARCH="$MOUNTIN_TARGET_ARCH" CROSS_COMPILE="$CROSS_COMPILE" \
    HOSTCC=cc defconfig
python3 /merge_config.py .config /busybox.config .config

# Accept defaults for any new options
yes "" | make ARCH="$MOUNTIN_TARGET_ARCH" \
    CROSS_COMPILE="$CROSS_COMPILE" HOSTCC=cc oldconfig || true

# Build static busybox
make -j"${MOUNTIN_BUILD_JOBS}" ARCH="$MOUNTIN_TARGET_ARCH" \
    CROSS_COMPILE="$CROSS_COMPILE" HOSTCC=cc CONFIG_STATIC=y busybox \
    busybox.links

# Copy to output
mkdir -p /host/build/bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}
mkdir -p /host/build/share/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}
cp -v busybox /host/build/bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/
cp -v busybox.links \
    /host/build/share/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/
"$STRIP" /host/build/bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/busybox
