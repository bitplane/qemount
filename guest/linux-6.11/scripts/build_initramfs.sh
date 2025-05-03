#!/bin/bash
set -euo pipefail

KERNEL_VERSION="$1"
KERNEL_ARCH="$2"
KERNEL_BUILD_DIR=$(realpath "$3")
STAGING_ROOTFS_DIR=$(realpath "$4")
FINAL_INITRAMFS_PATH=$(realpath "$5")

# Paths
MODULES_DIR="$STAGING_ROOTFS_DIR/lib/modules/${KERNEL_VERSION}"
TMP_CPIO=$(mktemp "${TMPDIR:-/tmp}/initramfs.cpio.XXXXXX")

# Install kernel modules (if any)
make -C "$KERNEL_BUILD_DIR" INSTALL_MOD_PATH="$STAGING_ROOTFS_DIR" INSTALL_MOD_STRIP=1 modules_install || true

# Generate modules.dep if needed
if [ -d "$MODULES_DIR" ] && find "$MODULES_DIR" -name '*.ko' | grep -q .; then
    echo "[initramfs] running depmod"
    depmod -b "$STAGING_ROOTFS_DIR" "$KERNEL_VERSION"
fi

# Create compressed initramfs archive
echo "[initramfs] building archive to $FINAL_INITRAMFS_PATH"
(cd "$STAGING_ROOTFS_DIR" && find . | cpio -o --format=newc > "$TMP_CPIO")
gzip -f -9 "$TMP_CPIO" -c > "$FINAL_INITRAMFS_PATH"
rm -f "$TMP_CPIO"

echo "[initramfs] done"
