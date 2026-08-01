#!/bin/sh
set -eu

SOURCE_ARCHIVE=/host/build/sources/linux-6.12.tar.xz
SOURCE_HASH=$(sha256sum "$SOURCE_ARCHIVE" | cut -d ' ' -f 1)
CACHE_DIR=/host/build/cache/linux/${ARCH}/6.12/kernel-v1/${SOURCE_HASH}
SOURCE_DIR=$CACHE_DIR/source

if [ ! -f "$SOURCE_DIR/.qemount-source-ready" ]; then
    EXTRACT_DIR=$CACHE_DIR/source.tmp.$$
    rm -rf "$SOURCE_DIR"
    mkdir -p "$EXTRACT_DIR"
    trap 'rm -rf "$EXTRACT_DIR"' EXIT HUP INT TERM
    tar -xf "$SOURCE_ARCHIVE" -C "$EXTRACT_DIR" --strip-components=1
    touch "$EXTRACT_DIR/.qemount-source-ready"
    mv "$EXTRACT_DIR" "$SOURCE_DIR"
    trap - EXIT HUP INT TERM
fi

cd "$SOURCE_DIR"

# Copy config files
cp /kernel.config /filesystems.config .

# Determine kernel arch
KERNEL_ARCH=$ARCH
[ "$ARCH" = "aarch64" ] && KERNEL_ARCH=arm64

# Build kernel
make ARCH=$KERNEL_ARCH defconfig
./scripts/kconfig/merge_config.sh -m .config kernel.config filesystems.config
yes "" | make ARCH=$KERNEL_ARCH oldconfig
make ARCH=$KERNEL_ARCH -j"${JOBS}"

# Copy kernel image
mkdir -p /host/build/bin/qemu/${ARCH}-linux/6.12
if [ "$ARCH" = "x86_64" ]; then
    cp -v arch/x86_64/boot/bzImage /host/build/bin/qemu/${ARCH}-linux/6.12/kernel
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    cp -v arch/arm64/boot/Image.gz /host/build/bin/qemu/${ARCH}-linux/6.12/kernel
elif [ "$ARCH" = "arm" ]; then
    cp -v arch/arm/boot/zImage /host/build/bin/qemu/${ARCH}-linux/6.12/kernel
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi
