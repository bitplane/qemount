#!/bin/sh
set -eu

SOURCE_ARCHIVE=/host/build/sources/linux-6.12.tar.xz
CACHE_DIR=$MOUNTIN_CACHE_DIR
SOURCE_DIR=$CACHE_DIR/source

if [ ! -d "$SOURCE_DIR" ]; then
    EXTRACT_DIR=$CACHE_DIR/source.tmp.$$
    rm -rf "$SOURCE_DIR"
    mkdir -p "$EXTRACT_DIR"
    trap 'rm -rf "$EXTRACT_DIR"' EXIT HUP INT TERM
    tar --no-same-owner -xf "$SOURCE_ARCHIVE" \
        -C "$EXTRACT_DIR" --strip-components=1
    mv "$EXTRACT_DIR" "$SOURCE_DIR"
    trap - EXIT HUP INT TERM
fi

cd "$SOURCE_DIR"

# Copy config files
cp /kernel.config /filesystems.config .

# Determine kernel arch
KERNEL_ARCH=$MOUNTIN_TARGET_ARCH
[ "$MOUNTIN_TARGET_ARCH" = "aarch64" ] && KERNEL_ARCH=arm64
if [ "$MOUNTIN_TARGET_ARCH" = "x86_64" ]; then
    KERNEL_TARGET=bzImage
    KERNEL_IMAGE=arch/x86_64/boot/bzImage
elif [ "$MOUNTIN_TARGET_ARCH" = "aarch64" ]; then
    KERNEL_TARGET=Image.gz
    KERNEL_IMAGE=arch/arm64/boot/Image.gz
else
    echo "Unsupported architecture: $MOUNTIN_TARGET_ARCH"
    exit 1
fi

# Build kernel
make ARCH="$KERNEL_ARCH" CROSS_COMPILE="$CROSS_COMPILE" HOSTCC=cc defconfig
./scripts/kconfig/merge_config.sh -m .config kernel.config filesystems.config
yes "" | make ARCH="$KERNEL_ARCH" CROSS_COMPILE="$CROSS_COMPILE" \
    HOSTCC=cc oldconfig
make ARCH="$KERNEL_ARCH" CROSS_COMPILE="$CROSS_COMPILE" HOSTCC=cc \
    -j"${MOUNTIN_BUILD_JOBS}" "$KERNEL_TARGET"

# Copy kernel image
mkdir -p /host/build/guest/${MOUNTIN_TARGET_ARCH}-linux/6.12
cp -v "$KERNEL_IMAGE" \
    /host/build/guest/${MOUNTIN_TARGET_ARCH}-linux/6.12/kernel
