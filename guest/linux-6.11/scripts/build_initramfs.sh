#!/bin/bash
#
# guest/linux-6.11/scripts/build_initramfs.sh
#
# Creates a compressed CPIO initramfs image.
# Copies BusyBox, kernel modules (stripped), and the init script.
# Relies on devtmpfs in the kernel to create device nodes.
#
# Usage:
# ./build_initramfs.sh <KERNEL_VERSION> <KERNEL_ARCH> <KERNEL_BUILD_DIR> \
#                      <BUSYBOX_INSTALL_DIR> <INIT_SH_TEMPLATE_PATH> \
#                      <FINAL_INITRAMFS_PATH> <CROSS_COMPILE_PREFIX>

set -euo pipefail

# --- Argument Parsing ---
if [ "$#" -ne 7 ]; then
    echo "Usage: $0 <KERNEL_VERSION> <KERNEL_ARCH> <KERNEL_BUILD_DIR> <BUSYBOX_INSTALL_DIR> <INIT_SH_TEMPLATE_PATH> <FINAL_INITRAMFS_PATH> <CROSS_COMPILE_PREFIX>"
    exit 1
fi

KERNEL_VERSION="$1" # Expecting full version like 6.11.0 now
KERNEL_ARCH="$2"
KERNEL_BUILD_DIR_REL="$3"  # Relative or absolute path to kernel build artifacts
BUSYBOX_INSTALL_DIR_REL="$4" # Relative or absolute path to busybox install dir
INIT_SH_TEMPLATE_PATH="$5" # Relative path to the source init.sh script
FINAL_INITRAMFS_PATH_REL="$6" # Relative or absolute path for the final output CPIO.GZ
CROSS_COMPILE_PREFIX="$7" # e.g., aarch64-linux-gnu-

# --- Resolve Paths ---
# Assumes this script is run from the guest/linux-6.11 directory by make -C
KERNEL_BUILD_DIR=$(realpath "$KERNEL_BUILD_DIR_REL")
BUSYBOX_INSTALL_DIR=$(realpath "$BUSYBOX_INSTALL_DIR_REL")
FINAL_INITRAMFS_PATH=$(realpath "$FINAL_INITRAMFS_PATH_REL")
# INIT_SH_TEMPLATE_PATH is relative to CWD (guest/linux-6.11)

# --- Check Prerequisites ---
# ... (prerequisite checks remain the same) ...
if [ ! -d "$KERNEL_BUILD_DIR" ]; then
    echo "Error: Kernel build directory '$KERNEL_BUILD_DIR' not found. Run kernel build first." >&2
    exit 1
fi
if [ ! -d "$BUSYBOX_INSTALL_DIR" ] || [ ! -f "$BUSYBOX_INSTALL_DIR/bin/busybox" ]; then
     echo "Error: BusyBox install directory '$BUSYBOX_INSTALL_DIR' seems incomplete. Run busybox build first." >&2
    exit 1
fi
if [ ! -f "$INIT_SH_TEMPLATE_PATH" ]; then
     echo "Error: Init script template '$INIT_SH_TEMPLATE_PATH' not found." >&2
    exit 1
fi
command -v cpio >/dev/null 2>&1 || { echo >&2 "Error: cpio command not found."; exit 1; }
command -v gzip >/dev/null 2>&1 || { echo >&2 "Error: gzip command not found."; exit 1; }
DEPMOD_CMD="depmod"


# --- Prepare Temporary Rootfs ---
TMP_ROOTFS_DIR=$(mktemp -d "${TMPDIR:-/tmp}/initramfs-rootfs.XXXXXX")
# *** Create temp CPIO file OUTSIDE the rootfs dir ***
INITRAMFS_CPIO_TMP=$(mktemp "${TMPDIR:-/tmp}/initramfs.cpio.XXXXXX")
echo "Created temporary rootfs directory: $TMP_ROOTFS_DIR"
echo "Temporary CPIO file: $INITRAMFS_CPIO_TMP"


cleanup() {
    echo "Cleaning up temporary rootfs: $TMP_ROOTFS_DIR"
    rm -rf "$TMP_ROOTFS_DIR"
    echo "Cleaning up temporary cpio file: $INITRAMFS_CPIO_TMP"
    rm -f "$INITRAMFS_CPIO_TMP"
}
trap cleanup EXIT # Ensure cleanup runs on script exit

# Create basic directory structure
echo "Creating basic filesystem structure..."
# Ensure KERNEL_VERSION passed in includes the patch level, e.g., 6.11.0
MODULES_SUBDIR="lib/modules/${KERNEL_VERSION}"
# NOTE: No /dev created here, relying on devtmpfs from the kernel
mkdir -p "$TMP_ROOTFS_DIR"/{bin,sbin,etc,proc,sys,tmp,mnt,usr/{bin,sbin},"${MODULES_SUBDIR}"}
chmod 1777 "$TMP_ROOTFS_DIR/tmp"

# --- Copy BusyBox ---
echo "Copying BusyBox installation..."
cp -a "$BUSYBOX_INSTALL_DIR"/* "$TMP_ROOTFS_DIR/"

# --- Install Kernel Modules (Stripped) ---
echo "Installing *stripped* kernel modules from $KERNEL_BUILD_DIR..."
# Check if modules exist before trying to install
MODULE_COUNT=$(find "$KERNEL_BUILD_DIR" -name '*.ko' -type f | wc -l)
if [ "$MODULE_COUNT" -eq 0 ]; then
    echo "Warning: No .ko files found in $KERNEL_BUILD_DIR. Kernel modules might not have been built correctly."
    # Still run modules_install for builtins, but the lack of .ko files is the core issue
fi
# Run modules_install - capture output to check for errors
INSTALL_LOG=$(mktemp "${TMPDIR:-/tmp}/modules_install.log.XXXXXX")
if ! make -C "$KERNEL_BUILD_DIR" INSTALL_MOD_PATH="$TMP_ROOTFS_DIR" INSTALL_MOD_STRIP=1 modules_install > "$INSTALL_LOG" 2>&1; then
    echo "Error during 'make modules_install'. Log:"
    cat "$INSTALL_LOG"
    rm -f "$INSTALL_LOG"
    # Consider exiting if modules are essential: exit 1
fi
rm -f "$INSTALL_LOG"

# Add a check *after* installation
INSTALLED_MODULE_COUNT=$(find "$TMP_ROOTFS_DIR/${MODULES_SUBDIR}" -name '*.ko' -type f | wc -l)
echo "Found $INSTALLED_MODULE_COUNT .ko files installed in initramfs."
if [ "$INSTALLED_MODULE_COUNT" -eq 0 ] && [ "$MODULE_COUNT" -gt 0 ]; then
    echo "Error: modules_install seems to have failed to copy .ko files! Check kernel build output."
    # Consider exiting here if modules are essential: exit 1
fi


# --- Generate modules.dep ---
# Only run depmod if modules were actually installed
if [ "$INSTALLED_MODULE_COUNT" -gt 0 ]; then
    echo "Generating modules.dep..."
    # Use the full KERNEL_VERSION here
    "$DEPMOD_CMD" -b "$TMP_ROOTFS_DIR" "$KERNEL_VERSION"
else
    echo "Skipping depmod generation as no modules were installed."
fi

# --- Copy Init Script ---
echo "Copying init script..."
cp "$INIT_SH_TEMPLATE_PATH" "$TMP_ROOTFS_DIR/init"
chmod +x "$TMP_ROOTFS_DIR/init"

# --- Create Device Nodes (Minimal) ---
# echo "Creating minimal device nodes..." # Removed mknod calls
# Relying on CONFIG_DEVTMPFS=y and CONFIG_DEVTMPFS_MOUNT=y in kernel config

# --- Create CPIO Archive ---
echo "Creating CPIO archive: $INITRAMFS_CPIO_TMP"
# *** Archive from TMP_ROOTFS_DIR, output to INITRAMFS_CPIO_TMP (outside) ***
(cd "$TMP_ROOTFS_DIR" && find . | cpio -o --format=newc > "$INITRAMFS_CPIO_TMP")

# --- Compress Archive and Move to Final Location ---
echo "Compressing CPIO archive to $FINAL_INITRAMFS_PATH..."
gzip -f -9 "$INITRAMFS_CPIO_TMP" -c > "$FINAL_INITRAMFS_PATH"

if [ $? -ne 0 ]; then
    echo "Error: Failed to create or compress initramfs." >&2
    exit 1
fi

echo "Initramfs created successfully: $FINAL_INITRAMFS_PATH"
exit 0
