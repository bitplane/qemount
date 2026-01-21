#!/bin/sh
set -e

cd /work
tar -xf /host/build/sources/linux-2.6.39.4.tar.xz
cd linux-2.6.39.4

# Copy config files
cp /kernel.config /filesystems.config .

# Determine kernel arch
if [ "$ARCH" = "x86_64" ]; then
    KERNEL_ARCH=x86_64
elif [ "$ARCH" = "i386" ] || [ "$ARCH" = "i686" ]; then
    KERNEL_ARCH=i386
else
    echo "Unsupported architecture for 2.6 kernel: $ARCH"
    exit 1
fi

# Build kernel
make ARCH=$KERNEL_ARCH defconfig
cat kernel.config filesystems.config >> .config
yes "" | make ARCH=$KERNEL_ARCH oldconfig
make ARCH=$KERNEL_ARCH -j${JOBS}

# Copy kernel image
mkdir -p /host/build/bin/qemu/${ARCH}-linux/2.6
if [ "$ARCH" = "x86_64" ]; then
    cp -v arch/x86_64/boot/bzImage /host/build/bin/qemu/${ARCH}-linux/2.6/kernel
else
    cp -v arch/x86/boot/bzImage /host/build/bin/qemu/${ARCH}-linux/2.6/kernel
fi
