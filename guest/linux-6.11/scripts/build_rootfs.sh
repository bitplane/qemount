#!/bin/bash
set -euo pipefail

TARGET_ARCH="$1"
SOURCE_ROOTFS_DIR=$(realpath "$2")
STAGING_ROOTFS_DIR=$(realpath "$3")
CACHE_DIR=$(realpath "$4")
BUSYBOX_INSTALL_DIR=$(realpath "$5")
CROSS_COMPILE="${CROSS_COMPILE:-}"

echo "[rootfs] preparing: $STAGING_ROOTFS_DIR"

# Start fresh
mkdir -p "$STAGING_ROOTFS_DIR"
find "$STAGING_ROOTFS_DIR" -mindepth 1 -delete

# Overlay rootfs
echo "[rootfs] copying overlay from $SOURCE_ROOTFS_DIR"
cd "$SOURCE_ROOTFS_DIR"
find . -print0 | cpio --null -pd "$STAGING_ROOTFS_DIR"

# Ensure required dirs exist
for d in proc sys tmp mnt dev bin sbin etc usr lib; do
    mkdir -p "$STAGING_ROOTFS_DIR/$d"
done
chmod 1777 "$STAGING_ROOTFS_DIR/tmp"

# Ensure /init is executable
[ -f "$STAGING_ROOTFS_DIR/init" ] && chmod +x "$STAGING_ROOTFS_DIR/init"

# Install busybox
echo "[rootfs] installing busybox from $BUSYBOX_INSTALL_DIR"
rsync -a "$BUSYBOX_INSTALL_DIR"/ "$STAGING_ROOTFS_DIR"/

echo "[rootfs] done"
