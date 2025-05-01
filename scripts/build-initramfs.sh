#!/bin/bash
set -eux

ARCH=${ARCH:-x86_64}
KERNEL_VERSION=${KERNEL_VERSION:-6.5}
BUSYBOX_VERSION=${BUSYBOX_VERSION:-1.36.1}
INITRAMFS_IMAGE=${INITRAMFS_IMAGE:-build/initramfs/initramfs.cpio.gz}

INITRAMFS_DIR=$(dirname "$INITRAMFS_IMAGE" | sed 's/\.cpio\.gz$//')/rootfs
mkdir -p "$INITRAMFS_DIR"
cd build/initramfs

# Download BusyBox
if [ ! -f busybox-$BUSYBOX_VERSION.tar.bz2 ]; then
    wget https://busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2
fi
if [ ! -d busybox-$BUSYBOX_VERSION ]; then
    tar xf busybox-$BUSYBOX_VERSION.tar.bz2
fi
cd busybox-$BUSYBOX_VERSION

# Configure BusyBox
CONFIG_PATH="../../../config/initramfs/$ARCH/busybox.config"
if [ -f "$CONFIG_PATH" ]; then
    echo "Using saved BusyBox config for $ARCH"
    cp "$CONFIG_PATH" .config
else
    echo "No config found, generating with defconfig..."
    make defconfig
    mkdir -p "$(dirname "$CONFIG_PATH")"
    cp .config "$CONFIG_PATH"
fi

make -j"$(nproc)"
make CONFIG_PREFIX="$PWD/../rootfs" install

cd ../rootfs
mkdir -p etc dev proc sys tmp
chmod 1777 tmp

# Add kernel module if available
KMOD_SRC=../../linux-${KERNEL_VERSION}/fs/isofs/isofs.ko
if [ -f "$KMOD_SRC" ]; then
    mkdir -p lib/modules/$KERNEL_VERSION/kernel/fs/isofs
    cp "$KMOD_SRC" lib/modules/$KERNEL_VERSION/kernel/fs/isofs/
fi

# Copy init script
cp ../../../overlays/shared/init init
chmod +x init

# Generate initramfs
cd ..
find rootfs | cpio -o --format=newc > "${INITRAMFS_IMAGE%.gz}"
gzip -f "${INITRAMFS_IMAGE%.gz}"

echo "Initramfs build complete: $INITRAMFS_IMAGE"
