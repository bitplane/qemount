#!/bin/bash
set -eux

ARCH="$1"
BUSYBOX_VERSION="$2"
KERNEL_VERSION="$3"
INITRAMFS_IMAGE="$4"

ROOTFS_DIR="build/initramfs/rootfs"
SRC_DIR="build/initramfs/busybox-${BUSYBOX_VERSION}"
INSTALL_DIR="$SRC_DIR/_install"

rm -rf "$ROOTFS_DIR"
mkdir -p "$ROOTFS_DIR"/{etc,dev,proc,sys,tmp}
cp -a "$INSTALL_DIR"/. "$ROOTFS_DIR/"
chmod 1777 "$ROOTFS_DIR/tmp"

cp overlays/shared/init "$ROOTFS_DIR/init"
chmod +x "$ROOTFS_DIR/init"

# Copy ISO9660 module if present
MOD_SRC="build/linux/linux-${KERNEL_VERSION}/fs/isofs/isofs.ko"
if [ -f "$MOD_SRC" ]; then
    mkdir -p "$ROOTFS_DIR/lib/modules/${KERNEL_VERSION}/kernel/fs/isofs"
    cp "$MOD_SRC" "$ROOTFS_DIR/lib/modules/${KERNEL_VERSION}/kernel/fs/isofs/"
fi

pushd "$ROOTFS_DIR"
find . | cpio -o --format=newc > ../rootfs.cpio
popd

gzip -f build/initramfs/rootfs.cpio
mv build/initramfs/rootfs.cpio.gz "$INITRAMFS_IMAGE"
