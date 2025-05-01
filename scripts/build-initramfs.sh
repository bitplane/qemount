#!/bin/bash
set -eux

ARCH=$1
BUSYBOX_VERSION=$2
KERNEL_VERSION=$3
INITRAMFS_IMAGE=$4

INITRAMFS_DIR=$(dirname "$INITRAMFS_IMAGE")
ROOTFS_DIR="$INITRAMFS_DIR/rootfs"
SRC_DIR="$INITRAMFS_DIR/busybox-$BUSYBOX_VERSION"
INSTALL_DIR="$SRC_DIR/_install"

rm -rf "$ROOTFS_DIR"
mkdir -p "$ROOTFS_DIR"/{etc,dev,proc,sys,tmp}
chmod 1777 "$ROOTFS_DIR/tmp"

# Copy BusyBox install
cp -a "$INSTALL_DIR/." "$ROOTFS_DIR/"

# Optional: add kernel module
KMOD_SRC="build/linux/linux-${KERNEL_VERSION}/fs/isofs/isofs.ko"
if [ -f "$KMOD_SRC" ]; then
    mkdir -p "$ROOTFS_DIR/lib/modules/$KERNEL_VERSION/kernel/fs/isofs"
    cp "$KMOD_SRC" "$ROOTFS_DIR/lib/modules/$KERNEL_VERSION/kernel/fs/isofs/"
fi

# Init script
cp overlays/shared/init "$ROOTFS_DIR/init"
chmod +x "$ROOTFS_DIR/init"

# Generate initramfs
OUTFILE="${INITRAMFS_IMAGE%.gz}"
pushd "$ROOTFS_DIR"
find . | cpio -o --format=newc > "$OLDPWD/$OUTFILE"
popd
gzip -f "$OUTFILE"
