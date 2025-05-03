#!/bin/bash
#
# guest/linux-6.11/scripts/build_rootfs.sh
#
# Prepares a staging directory for the initramfs by:
# 1. Copying the base source rootfs.
# 2. Building the 9pserve binary (using build_9p.sh) into the cache.
# 3. Copying the built 9pserve binary from the cache into the staging rootfs's /bin.
#
# Usage:
# ./build_rootfs.sh <TARGET_ARCH> <SOURCE_ROOTFS_DIR> <STAGING_ROOTFS_DIR> \
#                   <CACHE_DIR> <BUILD_9P_SCRIPT_PATH>

set -euo pipefail

# --- Argument Parsing ---
# Removed FINAL_9PSERVE_PATH argument
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <TARGET_ARCH> <SOURCE_ROOTFS_DIR> <STAGING_ROOTFS_DIR> <CACHE_DIR> <BUILD_9P_SCRIPT_PATH>"
    exit 1
fi

TARGET_ARCH="$1"
SOURCE_ROOTFS_DIR_REL="$2"    # e.g., ../rootfs
STAGING_ROOTFS_DIR_REL="$3"   # e.g., ../../build/cache/linux-6.11-rootfs-staging
CACHE_DIR_REL="$4"            # e.g., ../../build/cache
BUILD_9P_SCRIPT_PATH_REL="$5" # e.g., ./build_9p.sh

# --- Resolve Paths ---
# Assuming script is run from guest/linux-6.11/scripts
SOURCE_ROOTFS_DIR=$(realpath "$SOURCE_ROOTFS_DIR_REL")
STAGING_ROOTFS_DIR=$(realpath "$STAGING_ROOTFS_DIR_REL")
CACHE_DIR=$(realpath "$CACHE_DIR_REL")
BUILD_9P_SCRIPT_PATH=$(realpath "$BUILD_9P_SCRIPT_PATH_REL")

# Define a path for the 9pserve binary within the cache directory
NINEPSERVE_CACHE_PATH="$CACHE_DIR/9pserve-$(basename "$STAGING_ROOTFS_DIR")" # Add staging dir name for uniqueness if needed

# --- Check Prerequisites ---
if [ ! -d "$SOURCE_ROOTFS_DIR" ]; then
    echo "Error: Source rootfs directory '$SOURCE_ROOTFS_DIR' not found." >&2
    exit 1
fi
if [ ! -f "$SOURCE_ROOTFS_DIR/init" ]; then
    echo "Error: Source rootfs directory '$SOURCE_ROOTFS_DIR' must contain an 'init' script." >&2
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


# --- Prepare Staging Directory ---
echo "Preparing staging rootfs directory: $STAGING_ROOTFS_DIR"
# Clean staging dir first
rm -rf "$STAGING_ROOTFS_DIR"
mkdir -p "$STAGING_ROOTFS_DIR"

# --- Populate Staging Directory ---
# 1. Copy the source rootfs contents
echo "Copying source rootfs from $SOURCE_ROOTFS_DIR..."
# Use cp -a to preserve permissions, ownership (if possible), links etc.
# Add /* to copy contents, not the directory itself
cp -a "$SOURCE_ROOTFS_DIR"/* "$STAGING_ROOTFS_DIR/"
# Ensure basic directories exist if source rootfs was minimal
mkdir -p "$STAGING_ROOTFS_DIR"/{proc,sys,tmp,mnt,bin,lib/modules} # Ensure bin and lib/modules exist
chmod 1777 "$STAGING_ROOTFS_DIR/tmp" # Ensure /tmp is world-writable
chmod +x "$STAGING_ROOTFS_DIR/init" # Ensure init is executable

# 2. Build the 9pserve binary using the dedicated script into the CACHE
echo "Building 9pserve binary into cache: $NINEPSERVE_CACHE_PATH..."
# Call the build_9p script, telling it to output to the cache path
"$BUILD_9P_SCRIPT_PATH" "$TARGET_ARCH" "$NINEPSERVE_CACHE_PATH" "$CACHE_DIR"
if [ $? -ne 0 ]; then
    echo "Error: build_9p.sh failed." >&2
    exit 1
fi
if [ ! -f "$NINEPSERVE_CACHE_PATH" ]; then
    echo "Error: 9pserve binary was not created at cache path '$NINEPSERVE_CACHE_PATH'." >&2
    exit 1
fi

# 3. Copy the *built* 9pserve binary from the CACHE into the staging rootfs
echo "Copying built 9pserve binary from cache to $STAGING_ROOTFS_DIR/bin/..."
cp "$NINEPSERVE_CACHE_PATH" "$STAGING_ROOTFS_DIR/bin/9pserve"
if [ $? -ne 0 ]; then
    echo "Error: Failed to copy 9pserve from cache to staging directory." >&2
    exit 1
fi
chmod +x "$STAGING_ROOTFS_DIR/bin/9pserve" # Ensure executable

echo "Staging rootfs prepared successfully at: $STAGING_ROOTFS_DIR"

# The Makefile should create a stamp file based on this script's success
exit 0
