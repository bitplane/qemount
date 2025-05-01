#!/bin/bash
ARCH=${ARCH:-x86_64}

# Script to build an initramfs cpio with BusyBox and kernel modules
BUSYBOX_VERSION=$1
KERNEL_VERSION=$2

set -eux

INITRAMFS_DIR=build/initramfs/rootfs
mkdir -p $INITRAMFS_DIR
cd build/initramfs

# Download BusyBox
if [ ! -f busybox-$BUSYBOX_VERSION.tar.bz2 ]; then
    wget https://busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2
fi
if [ ! -d busybox-$BUSYBOX_VERSION ]; then
    tar xf busybox-$BUSYBOX_VERSION.tar.bz2
fi
cd busybox-$BUSYBOX_VERSION

# Configure minimal BusyBox
cp ../../../config/initramfs/$ARCH/busybox.config .config

# Build and install BusyBox
make -j$(nproc)
make CONFIG_PREFIX=$PWD/../rootfs install

cd ../rootfs
mkdir -p etc dev proc sys tmp
chmod 1777 tmp

# Add kernel module if exists
KMOD_SRC=../../linux-${KERNEL_VERSION}/fs/isofs/isofs.ko
if [ -f $KMOD_SRC ]; then
    mkdir -p lib/modules/$KERNEL_VERSION/kernel/fs/isofs
    cp $KMOD_SRC lib/modules/$KERNEL_VERSION/kernel/fs/isofs/
fi

# Create initramfs image
cd ..
find rootfs | cpio -o --format=newc > ../initramfs.cpio
gzip -f ../initramfs.cpio

echo "Initramfs build complete: initramfs.cpio.gz"
