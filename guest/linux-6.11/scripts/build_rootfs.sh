#!/bin/bash
#
# guest/linux-6.11/scripts/build_rootfs.sh
#
# Prepares a staging directory for the initramfs by:
# 1. Copying the base source rootfs.
# 2. Verifying and copying the installed BusyBox files.
# 3. Building the 9pserve binary (calling build_9p.sh from the same directory) into the cache.
# 4. Copying the built 9pserve binary from the cache into the staging rootfs's /bin.
#
# Usage:
# ./build_rootfs.sh <TARGET_ARCH> <SOURCE_ROOTFS_DIR> <STAGING_ROOTFS_DIR> \
#                   <CACHE_DIR> <BUSYBOX_INSTALL_DIR>

set -euo pipefail

# --- Argument Parsing ---
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <TARGET_ARCH> <SOURCE_ROOTFS_DIR> <STAGING_ROOTFS_DIR> <CACHE_DIR> <BUSYBOX_INSTALL_DIR>"
    exit 1
fi

TARGET_ARCH="$1"
SOURCE_ROOTFS_DIR_REL="$2"    # e.g., ../rootfs
STAGING_ROOTFS_DIR_REL="$3"   # e.g., ../../build/cache/linux-6.11-rootfs-staging
CACHE_DIR_REL="$4"            # e.g., ../../build/cache
BUSYBOX_INSTALL_DIR_REL="$5"  # e.g., ../../build/cache/linux-6.11-busybox-x86_64-install

# --- Resolve Paths ---
# Get the absolute path of the directory this script is in
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
# Get the absolute path of the directory the Makefile called us from (current working directory)
CALLER_CWD=$(pwd)

# Construct absolute paths *without* requiring the final component to exist yet
# Assume relative paths are relative to the CALLER_CWD (where make was run)
SOURCE_ROOTFS_DIR=$(readlink -f "$CALLER_CWD/$SOURCE_ROOTFS_DIR_REL")
STAGING_ROOTFS_DIR="$CALLER_CWD/$STAGING_ROOTFS_DIR_REL" # Don't resolve yet, mkdir -p handles it
CACHE_DIR=$(readlink -f "$CALLER_CWD/$CACHE_DIR_REL")
BUSYBOX_INSTALL_DIR=$(readlink -f "$CALLER_CWD/$BUSYBOX_INSTALL_DIR_REL")

# Build script path is relative to *this* script's location
BUILD_9P_SCRIPT_PATH="$SCRIPT_DIR/build_9p.sh"

# Define a path for the 9pserve binary within the cache directory
# Use the resolved CACHE_DIR path
NINEPSERVE_CACHE_PATH="$CACHE_DIR/9pserve-$(basename "$STAGING_ROOTFS_DIR_REL")" # Basename is okay here

# --- Check Prerequisites ---
# Use the resolved absolute paths for checks
if [ ! -d "$SOURCE_ROOTFS_DIR" ]; then
    echo "Error: Source rootfs directory '$SOURCE_ROOTFS_DIR' not found (resolved from '$SOURCE_ROOTFS_DIR_REL')." >&2
    exit 1
fi
if [ ! -f "$SOURCE_ROOTFS_DIR/init" ]; then
    echo "Error: Source rootfs directory '$SOURCE_ROOTFS_DIR' must contain an 'init' script." >&2
    exit 1
fi
if [ ! -d "$BUSYBOX_INSTALL_DIR" ]; then
    echo "Error: BusyBox install directory '$BUSYBOX_INSTALL_DIR' not found (resolved from '$BUSYBOX_INSTALL_DIR_REL')." >&2
    exit 1
fi
if [ ! -f "$BUSYBOX_INSTALL_DIR/bin/busybox" ]; then
    echo "Error: BusyBox binary '$BUSYBOX_INSTALL_DIR/bin/busybox' not found. Build BusyBox first." >&2
    ls -lR "$BUSYBOX_INSTALL_DIR" # Show what IS there
    exit 1
fi
if [ ! -f "$BUILD_9P_SCRIPT_PATH" ]; then
    echo "Error: Build 9P script '$BUILD_9P_SCRIPT_PATH' not found." >&2
    exit 1
fi
if [ ! -x "$BUILD_9P_SCRIPT_PATH" ]; then
    echo "Error: Build 9P script '$BUILD_9P_SCRIPT_PATH' is not executable." >&2
    exit 1
fi
echo "BusyBox install directory appears valid: $BUSYBOX_INSTALL_DIR"


# --- Prepare Staging Directory ---
echo "Preparing staging rootfs directory: $STAGING_ROOTFS_DIR"
# Clean staging dir first
rm -rf "$STAGING_ROOTFS_DIR"
# Use mkdir -p which handles creating the path safely
mkdir -p "$STAGING_ROOTFS_DIR"
if [ $? -ne 0 ]; then
    echo "Error: Failed to create staging directory '$STAGING_ROOTFS_DIR'." >&2
    exit 1
fi


# --- Populate Staging Directory ---
# 1. Copy the source rootfs contents (init script, etc.)
echo "Copying source rootfs from $SOURCE_ROOTFS_DIR..."
rsync -a --info=progress2 "$SOURCE_ROOTFS_DIR/" "$STAGING_ROOTFS_DIR/"
# Ensure basic directories exist if source rootfs was minimal
mkdir -p "$STAGING_ROOTFS_DIR"/{proc,sys,tmp,mnt,bin,sbin,etc,usr,lib}
chmod 1777 "$STAGING_ROOTFS_DIR/tmp"
chmod +x "$STAGING_ROOTFS_DIR/init"

# 2. Copy the installed BusyBox files into the staging directory
echo "Copying BusyBox installation from $BUSYBOX_INSTALL_DIR..."
rsync -a --info=progress2 "$BUSYBOX_INSTALL_DIR/" "$STAGING_ROOTFS_DIR/"
# Explicitly check if essential files were copied
if [ ! -e "$STAGING_ROOTFS_DIR/bin/busybox" ]; then
     echo "Error: /bin/busybox was NOT copied from $BUSYBOX_INSTALL_DIR to $STAGING_ROOTFS_DIR/bin !"
     exit 1
fi
if [ ! -e "$STAGING_ROOTFS_DIR/bin/sh" ]; then
     echo "Error: /bin/sh was NOT copied or linked correctly in $STAGING_ROOTFS_DIR/bin !"
     echo "Contents of $STAGING_ROOTFS_DIR/bin:"
     ls -l "$STAGING_ROOTFS_DIR/bin"
     exit 1
fi
echo "BusyBox files copied successfully."

# 3. Build the 9pserve binary
echo "Building 9pserve binary into cache: $NINEPSERVE_CACHE_PATH..."
# Ensure cache directory exists before build_9p tries to write to it
mkdir -p "$(dirname "$NINEPSERVE_CACHE_PATH")"
"$BUILD_9P_SCRIPT_PATH" "$TARGET_ARCH" "$NINEPSERVE_CACHE_PATH" "$CACHE_DIR"
if [ $? -ne 0 ]; then echo "Error: build_9p.sh failed." >&2; exit 1; fi
if [ ! -f "$NINEPSERVE_CACHE_PATH" ]; then echo "Error: 9pserve binary not created at '$NINEPSERVE_CACHE_PATH'." >&2; exit 1; fi

# 4. Copy the *built* 9pserve binary from the CACHE into the staging rootfs /bin
echo "Copying built 9pserve binary from cache to $STAGING_ROOTFS_DIR/bin/..."
cp "$NINEPSERVE_CACHE_PATH" "$STAGING_ROOTFS_DIR/bin/9pserve"
if [ $? -ne 0 ]; then echo "Error: Failed to copy 9pserve from cache." >&2; exit 1; fi
chmod +x "$STAGING_ROOTFS_DIR/bin/9pserve"

echo "Staging rootfs prepared successfully at: $STAGING_ROOTFS_DIR"
exit 0
