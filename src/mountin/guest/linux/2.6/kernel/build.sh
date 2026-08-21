#!/bin/sh
set -eu

SOURCE_ARCHIVE=/host/build/sources/linux-2.6.39.4.tar.xz
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

# Compatibility changes already carried by later upstream Linux releases.
cp /compiler-gcc5.h include/linux/compiler-gcc5.h
if grep -q 'defined(@val)' kernel/timeconst.pl; then
    patch -p1 < /modern-perl.patch
fi

# Copy config files
cp /kernel.config /filesystems.config .

# Determine kernel arch
if [ "$MOUNTIN_TARGET_ARCH" = "x86_64" ]; then
    KERNEL_ARCH=x86_64
elif [ "$MOUNTIN_TARGET_ARCH" = "i386" ] || [ "$MOUNTIN_TARGET_ARCH" = "i686" ]; then
    KERNEL_ARCH=i386
else
    echo "Unsupported architecture for 2.6 kernel: $MOUNTIN_TARGET_ARCH"
    exit 1
fi

# Build kernel
make ARCH=$KERNEL_ARCH CROSS_COMPILE="$CROSS_COMPILE" defconfig
cat kernel.config filesystems.config >> .config
yes "" | make ARCH=$KERNEL_ARCH CROSS_COMPILE="$CROSS_COMPILE" oldconfig
make ARCH=$KERNEL_ARCH CROSS_COMPILE="$CROSS_COMPILE" \
    -j"${MOUNTIN_BUILD_JOBS}"

# Copy kernel image
mkdir -p /host/build/guest/${MOUNTIN_TARGET_ARCH}-linux/2.6
if [ "$MOUNTIN_TARGET_ARCH" = "x86_64" ]; then
    cp -v arch/x86_64/boot/bzImage /host/build/guest/${MOUNTIN_TARGET_ARCH}-linux/2.6/kernel
else
    cp -v arch/x86/boot/bzImage /host/build/guest/${MOUNTIN_TARGET_ARCH}-linux/2.6/kernel
fi
