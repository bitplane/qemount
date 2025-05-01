#!/bin/bash

# Placeholder script to build an initramfs cpio with BusyBox and necessary tools/modules
BUSYBOX_VERSION=$1
KERNEL_VERSION=$2

set -eux

INITRAMFS_DIR=build/initramfs/rootfs
mkdir -p $INITRAMFS_DIR

echo "Building BusyBox (v$BUSYBOX_VERSION)..."
cd build/initramfs
if [ ! -f busybox-$BUSYBOX_VERSION.tar.bz2 ]; then
    wget https://busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2
fi
if [ ! -d busybox-$BUSYBOX_VERSION ]; then
    tar xf busybox-$BUSYBOX_VERSION.tar.bz2
fi
cd busybox-$BUSYBOX_VERSION

# Configure BusyBox for minimal usage (e.g., using defconfig)
make defconfig

echo "Compiling BusyBox..."
make -j$(nproc)

echo "Installing BusyBox to initramfs rootfs..."
make CONFIG_PREFIX=$PWD/../rootfs install

echo "Setting up initramfs directories..."
cd ../rootfs
mkdir -p etc dev proc sys tmp
chmod 1777 tmp

# Add any additional files needed in initramfs (e.g., /etc/fstab, /etc/modprobe.d)
# For now, we can leave them empty or add placeholders
mkdir -p etc

echo "Adding kernel modules (if any) to initramfs..."
# Example: copy iso9660 module from kernel build (assuming previous build-kernel)
KMOD_SRC=../../linux-${KERNEL_VERSION}/fs/isofs/isofs.ko
if [ -f $KMOD_SRC ]; then
    mkdir -p lib/modules/$KERNEL_VERSION/kernel/fs/isofs
    cp $KMOD_SRC lib/modules/$KERNEL_VERSION/kernel/fs/isofs/
fi

# TODO: Copy any other necessary modules (e.g., udf.ko for ISO support)

echo "Creating initramfs cpio archive..."
cd ..
find rootfs | cpio -o --format=newc > ../initramfs.cpio
gzip -f ../initramfs.cpio

echo "Initramfs build complete: initramfs.cpio.gz"
