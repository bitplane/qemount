#!/bin/sh
set -e

cd /work
tar -xf /host/build/sources/linux-6.17.tar.xz
cd linux-6.17

# Copy config files
cp /kernel.config /filesystems.config .

# Determine kernel arch
KERNEL_ARCH=$ARCH
[ "$ARCH" = "aarch64" ] && KERNEL_ARCH=arm64

# Build kernel
make ARCH=$KERNEL_ARCH defconfig
./scripts/kconfig/merge_config.sh -m .config kernel.config filesystems.config
yes "" | make ARCH=$KERNEL_ARCH oldconfig
make ARCH=$KERNEL_ARCH -j$(nproc)

# Copy kernel image
mkdir -p /host/build/bin/qemu/linux-${ARCH}/6.17
if [ "$ARCH" = "x86_64" ]; then
    cp -v arch/x86_64/boot/bzImage /host/build/bin/qemu/linux-${ARCH}/6.17/kernel
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    cp -v arch/arm64/boot/Image.gz /host/build/bin/qemu/linux-${ARCH}/6.17/kernel
elif [ "$ARCH" = "arm" ]; then
    cp -v arch/arm/boot/zImage /host/build/bin/qemu/linux-${ARCH}/6.17/kernel
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi
