#!/bin/bash
#
# guest/linux-6.11/scripts/build_initramfs.sh
#
# Creates a compressed CPIO initramfs image from a pre-populated staging rootfs directory,
# adding only the kernel modules.
# Relies on devtmpfs in the kernel to create device nodes.
#
# Usage:
# ./build_initramfs.sh <KERNEL_VERSION> <KERNEL_ARCH> <KERNEL_BUILD_DIR> \
#                      <STAGING_ROOTFS_DIR> <FINAL_INITRAMFS_PATH>

set -euo pipefail

# --- Argument Parsing ---
if [ "$#" -ne 5 ]; then
    # Updated Usage message
    echo "Usage: $0 <KERNEL_VERSION> <KERNEL_ARCH> <KERNEL_BUILD_DIR> <STAGING_ROOTFS_DIR> <FINAL_INITRAMFS_PATH>"
    exit 1
fi

KERNEL_VERSION="$1" # Expecting full version like 6.11.0 now
KERNEL_ARCH="$2"
KERNEL_BUILD_DIR_REL="$3"      # Relative or absolute path to kernel build artifacts
STAGING_ROOTFS_DIR_REL="$4"    # Relative or absolute path to the prepared staging rootfs
FINAL_INITRAMFS_PATH_REL="$5"  # Relative or absolute path for the final output CPIO.GZ
# CROSS_COMPILE_PREFIX is assumed to be in the environment for make modules_install

# --- Resolve Paths ---
# Assuming script is run from guest/linux-6.11/scripts
KERNEL_BUILD_DIR=$(realpath "$KERNEL_BUILD_DIR_REL")
STAGING_ROOTFS_DIR=$(realpath "$STAGING_ROOTFS_DIR_REL")
FINAL_INITRAMFS_PATH=$(realpath "$FINAL_INITRAMFS_PATH_REL")

# --- Check Prerequisites ---
if [ ! -d "$KERNEL_BUILD_DIR" ]; then
    echo "Error: Kernel build directory '$KERNEL_BUILD_DIR' not found. Run kernel build first." >&2
    exit 1
fi
if [ ! -d "$STAGING_ROOTFS_DIR" ]; then
    echo "Error: Staging rootfs directory '$STAGING_ROOTFS_DIR' not found. Run build_rootfs.sh first." >&2
    exit 1
fi
if [ ! -f "$STAGING_ROOTFS_DIR/init" ]; then
    echo "Error: Staging rootfs directory '$STAGING_ROOTFS_DIR' must contain an 'init' script." >&2
    exit 1
fi
command -v cpio >/dev/null 2>&1 || { echo >&2 "Error: cpio command not found."; exit 1; }
command -v gzip >/dev/null 2>&1 || { echo >&2 "Error: gzip command not found."; exit 1; }
DEPMOD_CMD="depmod"


# --- Prepare Temporary CPIO file ---
# Create temp CPIO file OUTSIDE the staging dir
INITRAMFS_CPIO_TMP=$(mktemp "${TMPDIR:-/tmp}/initramfs.cpio.XXXXXX")
echo "Temporary CPIO file: $INITRAMFS_CPIO_TMP"


cleanup() {
    echo "Cleaning up temporary cpio file: $INITRAMFS_CPIO_TMP"
    rm -f "$INITRAMFS_CPIO_TMP"
}
trap cleanup EXIT # Ensure cleanup runs on script exit

# --- Add Kernel Modules to Staging Directory ---
MODULES_SUBDIR="lib/modules/${KERNEL_VERSION}"
# Ensure the target module directory exists within the staging area
mkdir -p "$STAGING_ROOTFS_DIR/${MODULES_SUBDIR}"

echo "Installing *stripped* kernel modules from $KERNEL_BUILD_DIR into $STAGING_ROOTFS_DIR..."
# Check if modules exist before trying to install
MODULE_COUNT=$(find "$KERNEL_BUILD_DIR" -name '*.ko' -type f | wc -l)
if [ "$MODULE_COUNT" -eq 0 ]; then
    echo "Note: No .ko files found in $KERNEL_BUILD_DIR. Only installing built-in module info."
    # This is expected if kernel drivers are built-in (=y)
fi
# Run modules_install - capture output to check for errors
INSTALL_LOG=$(mktemp "${TMPDIR:-/tmp}/modules_install.log.XXXXXX")
# Use INSTALL_MOD_PATH pointing to the staging directory
if ! make -C "$KERNEL_BUILD_DIR" INSTALL_MOD_PATH="$STAGING_ROOTFS_DIR" INSTALL_MOD_STRIP=1 modules_install > "$INSTALL_LOG" 2>&1; then
    echo "Error during 'make modules_install'. Log:"
    cat "$INSTALL_LOG"
    rm -f "$INSTALL_LOG"
    # Consider exiting if modules are essential: exit 1
fi
rm -f "$INSTALL_LOG"

# Check *after* installation if modules were expected but not found
INSTALLED_MODULE_COUNT=$(find "$STAGING_ROOTFS_DIR/${MODULES_SUBDIR}" -name '*.ko' -type f | wc -l)
echo "Found $INSTALLED_MODULE_COUNT .ko files installed in initramfs staging area."
if [ "$INSTALLED_MODULE_COUNT" -eq 0 ] && [ "$MODULE_COUNT" -gt 0 ]; then
    echo "Error: modules_install seems to have failed to copy .ko files! Check kernel build output."
    # Consider exiting here if modules were essential: exit 1
fi

# --- Generate modules.dep ---
# Only run depmod if modules were actually installed
if [ "$INSTALLED_MODULE_COUNT" -gt 0 ]; then
    echo "Generating modules.dep in $STAGING_ROOTFS_DIR..."
    # Use the full KERNEL_VERSION here, targeting the staging dir
    "$DEPMOD_CMD" -b "$STAGING_ROOTFS_DIR" "$KERNEL_VERSION"
else
    echo "Skipping depmod generation as no loadable modules were installed."
fi

# --- Create CPIO Archive ---
echo "Creating CPIO archive: $INITRAMFS_CPIO_TMP from $STAGING_ROOTFS_DIR"
# Archive from STAGING_ROOTFS_DIR, output to INITRAMFS_CPIO_TMP (outside)
(cd "$STAGING_ROOTFS_DIR" && find . | cpio -o --format=newc > "$INITRAMFS_CPIO_TMP")

# --- Compress Archive and Move to Final Location ---
echo "Compressing CPIO archive to $FINAL_INITRAMFS_PATH..."
gzip -f -9 "$INITRAMFS_CPIO_TMP" -c > "$FINAL_INITRAMFS_PATH"

if [ $? -ne 0 ]; then
    echo "Error: Failed to create or compress initramfs." >&2
    exit 1
fi

echo "Initramfs created successfully: $FINAL_INITRAMFS_PATH"
exit 0
