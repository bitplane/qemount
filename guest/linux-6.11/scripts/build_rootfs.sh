#!/bin/bash
set -euo pipefail

# --- Script Arguments ---
TARGET_ARCH="$1"             # e.g., x86_64, arm64
SOURCE_ROOTFS_DIR=$(realpath "$2") # Path to the source rootfs files (e.g., guest/linux-6.11/rootfs)
STAGING_ROOTFS_DIR=$(realpath "$3") # Path to build the staging rootfs (e.g., build/cache/...)
CACHE_DIR=$(realpath "$4")   # Path to the main cache directory
BUSYBOX_INSTALL_DIR=$(realpath "$5") # Path where busybox was installed
CROSS_COMPILE="${CROSS_COMPILE:-}" # Default to empty if not set

# --- Setup Paths ---
SCRIPT_DIR=$(dirname "$(realpath "$0")")
BUILD_9P_SCRIPT="$SCRIPT_DIR/build_9p.sh"
BUILD_SSHD_SCRIPT="$SCRIPT_DIR/build_sshd.sh"

NINEPSERVE_STAGING_PATH="$STAGING_ROOTFS_DIR/bin/diod"
DROBEAR_STAGING_PATH="$STAGING_ROOTFS_DIR/bin/dropbearmulti"

# --- Prepare Staging Directory ---
echo "Preparing staging rootfs directory: $STAGING_ROOTFS_DIR"
rm -rf "$STAGING_ROOTFS_DIR"
mkdir -p "$STAGING_ROOTFS_DIR"

# --- Copy Source Rootfs and Create Basic Structure ---
echo "Copying base rootfs structure from $SOURCE_ROOTFS_DIR"
rsync -a "$SOURCE_ROOTFS_DIR/" "$STAGING_ROOTFS_DIR/"

echo "Creating standard directories..."
mkdir -p "$STAGING_ROOTFS_DIR"/{proc,sys,tmp,mnt,dev,bin,sbin,etc,usr,lib}
chmod 1777 "$STAGING_ROOTFS_DIR/tmp"
if [ -f "$STAGING_ROOTFS_DIR/init" ]; then
    chmod +x "$STAGING_ROOTFS_DIR/init"
fi

# --- Copy BusyBox ---
echo "Copying BusyBox binaries from $BUSYBOX_INSTALL_DIR"
rsync -a "$BUSYBOX_INSTALL_DIR/" "$STAGING_ROOTFS_DIR/"

# --- Build and Copy 9P Server (diod) ---
#echo "Building and installing 9P server (diod)..."
#"$BUILD_9P_SCRIPT" \
#    "" \
#    "$TARGET_ARCH" \
#    "$CACHE_DIR" \
#    "$NINEPSERVE_STAGING_PATH" \
#    "$CROSS_COMPILE"

#if [ ! -f "$NINEPSERVE_STAGING_PATH" ]; then
#    echo "Error: 9P server binary failed to build or copy to $NINEPSERVE_STAGING_PATH" >&2
#    exit 1
#fi
#echo "9P server (diod) installed to $NINEPSERVE_STAGING_PATH"

# --- Build and Copy SSH Server (Dropbear) ---
echo "Building and installing SSH server (Dropbear)..."
"$BUILD_SSHD_SCRIPT" \
    "" \
    "$TARGET_ARCH" \
    "$CACHE_DIR" \
    "$DROBEAR_STAGING_PATH" \
    "$CROSS_COMPILE"

if [ ! -f "$DROBEAR_STAGING_PATH" ]; then
    echo "Error: Dropbear binary failed to build or copy to $DROBEAR_STAGING_PATH" >&2
    exit 1
fi
echo "Dropbear installed to $DROBEAR_STAGING_PATH"

echo "Rootfs staging complete in $STAGING_ROOTFS_DIR"
exit 0
