#!/bin/bash
set -euo pipefail

KERNEL_VERSION="$1"
KERNEL_ARCH="$2"
KERNEL_BUILD_DIR=$(realpath "$3")
STAGING_ROOTFS_DIR=$(realpath "$4")
FINAL_INITRAMFS_PATH=$(realpath "$5")

# Prepare paths
MODULES_SUBDIR="lib/modules/${KERNEL_VERSION}"
mkdir -p "$STAGING_ROOTFS_DIR/${MODULES_SUBDIR}"

# Install kernel modules
make -C "$KERNEL_BUILD_DIR" INSTALL_MOD_PATH="$STAGING_ROOTFS_DIR" INSTALL_MOD_STRIP=1 modules_install

# Generate modules.dep if modules exist
if [ "$(find "$STAGING_ROOTFS_DIR/${MODULES_SUBDIR}" -name '*.ko' -type f | wc -l)" -gt 0 ]; then
    depmod -b "$STAGING_ROOTFS_DIR" "$KERNEL_VERSION"
fi

# Create CPIO archive
INITRAMFS_CPIO_TMP=$(mktemp "${TMPDIR:-/tmp}/initramfs.cpio.XXXXXX")
(cd "$STAGING_ROOTFS_DIR" && find . | cpio -o --format=newc > "$INITRAMFS_CPIO_TMP")

# Compress and cleanup
gzip -f -9 "$INITRAMFS_CPIO_TMP" -c > "$FINAL_INITRAMFS_PATH"
rm -f "$INITRAMFS_CPIO_TMP"

exit 0