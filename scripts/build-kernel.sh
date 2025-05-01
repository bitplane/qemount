#!/bin/bash

# Placeholder script to download and build the Linux kernel
KERNEL_VERSION=$1
ARCH=$2

set -eux

BUILD_DIR=build/linux
KERNEL_ARCHIVE=linux-${KERNEL_VERSION}.tar.xz
KERNEL_SRC_DIR=linux-${KERNEL_VERSION}

mkdir -p $BUILD_DIR
cd $BUILD_DIR

if [ ! -f $KERNEL_ARCHIVE ]; then
    echo "Downloading Linux kernel source (v$KERNEL_VERSION)..."
    wget https://cdn.kernel.org/pub/linux/kernel/v6.x/$KERNEL_ARCHIVE
fi

if [ ! -d $KERNEL_SRC_DIR ]; then
    echo "Extracting kernel source..."
    tar xf $KERNEL_ARCHIVE
fi

cd $KERNEL_SRC_DIR

CONFIG_PATH=../../../config/kernel/$ARCH/minimal.config

if [ -f "$CONFIG_PATH" ]; then
    echo "Using minimal config from $CONFIG_PATH"
    cp $CONFIG_PATH .config
    make olddefconfig
else
    echo "No minimal config found, using defconfig"
    make ARCH=$ARCH defconfig
fi

# Remove old busybox build if needed
rm -rf ../../initramfs/busybox-

echo "Building kernel (this may take a while)..."
make -j$(nproc) ARCH=$ARCH

echo "Kernel build complete. Kernel image at arch/${ARCH}/boot/bzImage"
