#!/bin/bash
#
# guest/linux-6.11/scripts/build_initramfs.sh
#
# Creates a compressed CPIO initramfs image.
# Copies BusyBox, kernel modules, and the init script.
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

KERNEL_VERSION="$1"
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
# depmod might need to be cross-version if host != target
DEPMOD_CMD="depmod"
# Consider using depmod from kernel build tools if cross-compiling? For now, use host's.

# --- Prepare Temporary Rootfs ---
TMP_ROOTFS_DIR=$(mktemp -d "${TMPDIR:-/tmp}/initramfs-rootfs.XXXXXX")
echo "Created temporary rootfs directory: $TMP_ROOTFS_DIR"

cleanup() {
    echo "Cleaning up temporary rootfs: $TMP_ROOTFS_DIR"
    # Use sudo if needed, although created by user so shouldn't be necessary
    rm -rf "$TMP_ROOTFS_DIR"
}
trap cleanup EXIT # Ensure cleanup runs on script exit

# Create basic directory structure
echo "Creating basic filesystem structure..."
mkdir -p "$TMP_ROOTFS_DIR"/{bin,sbin,etc,proc,sys,dev,tmp,mnt,usr/{bin,sbin},lib/modules/${KERNEL_VERSION}}
chmod 1777 "$TMP_ROOTFS_DIR/tmp"

# --- Copy BusyBox ---
echo "Copying BusyBox installation..."
# Copy everything from the install dir
cp -a "$BUSYBOX_INSTALL_DIR"/* "$TMP_ROOTFS_DIR/"
# Ensure essential symlinks exist if not created by install (optional, depends on busybox config)
# Example: ln -sf /bin/busybox "$TMP_ROOTFS_DIR/bin/sh"

# --- Install Kernel Modules ---
echo "Installing kernel modules from $KERNEL_BUILD_DIR..."
# Use the modules_install target directly into the temporary rootfs
# ARCH and CROSS_COMPILE should be in the environment from the Makefile
make -C "$KERNEL_BUILD_DIR" INSTALL_MOD_PATH="$TMP_ROOTFS_DIR" modules_install

# --- Generate modules.dep ---
echo "Generating modules.dep..."
# Run depmod relative to the temporary rootfs
# Note: This uses the host's depmod. May need adjustment for cross-compilation if host/target differ significantly.
"$DEPMOD_CMD" -b "$TMP_ROOTFS_DIR" "$KERNEL_VERSION"

# --- Copy Init Script ---
echo "Copying init script..."
# CRITICAL: Copy the source init.sh to /init inside the rootfs
cp "$INIT_SH_TEMPLATE_PATH" "$TMP_ROOTFS_DIR/init"
chmod +x "$TMP_ROOTFS_DIR/init"

# --- Create Device Nodes (Minimal) ---
# mknod is needed in busybox config
echo "Creating minimal device nodes..."
mknod -m 660 "$TMP_ROOTFS_DIR/dev/console" c 5 1 || echo "Warning: Failed to create /dev/console node"
mknod -m 660 "$TMP_ROOTFS_DIR/dev/null" c 1 3    || echo "Warning: Failed to create /dev/null node"
# Add other essential nodes if needed (e.g., /dev/ttyS0, /dev/ram0, /dev/vda, /dev/sr0)
# Example: mknod -m 660 "$TMP_ROOTFS_DIR/dev/ttyS0" c 4 64
# Example: mknod -m 660 "$TMP_ROOTFS_DIR/dev/vda" b 254 0 # Virtio block device

# --- Create CPIO Archive ---
INITRAMFS_CPIO_TMP="${TMP_ROOTFS_DIR}/initramfs.cpio"
echo "Creating CPIO archive: $INITRAMFS_CPIO_TMP"
(cd "$TMP_ROOTFS_DIR" && find . | cpio -o --format=newc > "$INITRAMFS_CPIO_TMP")

# --- Compress Archive and Move to Final Location ---
echo "Compressing CPIO archive to $FINAL_INITRAMFS_PATH..."
gzip -f -9 "$INITRAMFS_CPIO_TMP" -c > "$FINAL_INITRAMFS_PATH"

if [ $? -ne 0 ]; then
    echo "Error: Failed to create or compress initramfs." >&2
    # rm -f "$FINAL_INITRAMFS_PATH" # Optionally remove partial file
    exit 1
fi

echo "Initramfs created successfully: $FINAL_INITRAMFS_PATH"

# Cleanup is handled by the trap
exit 0
