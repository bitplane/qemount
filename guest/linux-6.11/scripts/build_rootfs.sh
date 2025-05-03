#!/bin/bash
set -euo pipefail

TARGET_ARCH="$1"
SOURCE_ROOTFS_DIR=$(realpath "$2")
STAGING_ROOTFS_DIR=$(realpath "$3")
CACHE_DIR=$(realpath "$4")
BUSYBOX_INSTALL_DIR=$(realpath "$5")

SCRIPT_DIR=$(dirname "$(realpath "$0")")
BUILD_9P_SCRIPT="$SCRIPT_DIR/build_9p.sh"
NINEPSERVE_CACHE="$CACHE_DIR/9pserve-$(basename "$STAGING_ROOTFS_DIR")"

# Prepare staging directory
rm -rf "$STAGING_ROOTFS_DIR"
mkdir -p "$STAGING_ROOTFS_DIR"

# Copy source rootfs and create basic structure
rsync -a "$SOURCE_ROOTFS_DIR/" "$STAGING_ROOTFS_DIR/"
mkdir -p "$STAGING_ROOTFS_DIR"/{proc,sys,tmp,mnt,bin,sbin,etc,usr,lib}
chmod 1777 "$STAGING_ROOTFS_DIR/tmp"
chmod +x "$STAGING_ROOTFS_DIR/init"

# Copy BusyBox
rsync -a "$BUSYBOX_INSTALL_DIR/" "$STAGING_ROOTFS_DIR/"

# Build and copy 9pserve
"$BUILD_9P_SCRIPT" "$TARGET_ARCH" "$NINEPSERVE_CACHE" "$CACHE_DIR"
cp "$NINEPSERVE_CACHE" "$STAGING_ROOTFS_DIR/bin/9pserve"
chmod +x "$STAGING_ROOTFS_DIR/bin/9pserve"

exit 0
