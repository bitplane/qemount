#!/bin/sh
set -eu

SOURCE_ARCHIVE=/host/build/sources/linux-2.6.39.4.tar.xz
SOURCE_HASH=$(sha256sum "$SOURCE_ARCHIVE" | cut -d ' ' -f 1)
CACHE_DIR=/host/build/cache/linux/${OUTPUT_ARCH}/2.6/kernel-v1/${SOURCE_HASH}
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
if [ "$OUTPUT_ARCH" = "x86_64" ]; then
    KERNEL_ARCH=x86_64
elif [ "$OUTPUT_ARCH" = "i386" ] || [ "$OUTPUT_ARCH" = "i686" ]; then
    KERNEL_ARCH=i386
else
    echo "Unsupported architecture for 2.6 kernel: $OUTPUT_ARCH"
    exit 1
fi

# Build kernel
make ARCH=$KERNEL_ARCH defconfig
cat kernel.config filesystems.config >> .config
yes "" | make ARCH=$KERNEL_ARCH oldconfig
make ARCH=$KERNEL_ARCH -j"${JOBS}"

# Copy kernel image
mkdir -p /host/build/bin/qemu/${OUTPUT_ARCH}-linux/2.6
if [ "$OUTPUT_ARCH" = "x86_64" ]; then
    cp -v arch/x86_64/boot/bzImage /host/build/bin/qemu/${OUTPUT_ARCH}-linux/2.6/kernel
else
    cp -v arch/x86/boot/bzImage /host/build/bin/qemu/${OUTPUT_ARCH}-linux/2.6/kernel
fi
