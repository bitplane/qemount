#!/bin/bash
#
# guest/linux-6.11/scripts/build_busybox.sh
#
# Builds BusyBox and installs it to a specified directory.
# Relies on ARCH and CROSS_COMPILE environment variables being set by the calling Makefile.
#
# Usage:
# ./build_busybox.sh <BUSYBOX_VERSION> <KERNEL_ARCH> <BUSYBOX_CONFIG_FILE> \
#                    <CACHE_DIR> <BUSYBOX_INSTALL_DIR> <CROSS_COMPILE_PREFIX>

set -euo pipefail

# --- Argument Parsing ---
if [ "$#" -ne 6 ]; then
    echo "Usage: $0 <BUSYBOX_VERSION> <KERNEL_ARCH> <BUSYBOX_CONFIG_FILE> <CACHE_DIR> <BUSYBOX_INSTALL_DIR> <CROSS_COMPILE_PREFIX>"
    exit 1
fi

BUSYBOX_VERSION="$1"
KERNEL_ARCH="$2"         # e.g., x86_64, arm64 (Used for ARCH env var)
BUSYBOX_CONFIG_FILE_REL="$3" # Path relative to guest Makefile dir (e.g., config/busybox.x86_64.config)
CACHE_DIR_REL="$4"           # Relative or absolute path to cache root
BUSYBOX_INSTALL_DIR_REL="$5" # Relative or absolute path for the final install destination (_install)
CROSS_COMPILE_PREFIX="$6" # e.g., aarch64-linux-gnu- (Used for CROSS_COMPILE env var)

# --- Resolve Paths ---
# Convert potentially relative paths passed from makefile to absolute paths
# Assumes this script is run from the guest/linux-6.11 directory by make -C
CACHE_DIR=$(realpath "$CACHE_DIR_REL")
BUSYBOX_INSTALL_DIR=$(realpath "$BUSYBOX_INSTALL_DIR_REL")
# Resolve the config file path relative to the current directory (where make was invoked)
BUSYBOX_CONFIG_FILE_ABS=$(realpath "$BUSYBOX_CONFIG_FILE_REL")


# --- Path Setup ---
# Use CACHE_DIR for downloads and source extraction
BUSYBOX_TARBALL="$CACHE_DIR/busybox-$BUSYBOX_VERSION.tar.bz2"
BUSYBOX_SRC_CACHE="$CACHE_DIR/busybox-$BUSYBOX_VERSION" # Extracted source lives here

# --- Ensure Config File Exists ---
# Check the resolved absolute path
if [ ! -f "$BUSYBOX_CONFIG_FILE_ABS" ]; then
    echo "Error: Missing BusyBox config file: '$BUSYBOX_CONFIG_FILE_ABS' (Resolved from '$BUSYBOX_CONFIG_FILE_REL')" >&2
    exit 1
fi

# --- Ensure Install Directory Exists ---
# The script is responsible for creating the *final* install structure inside this dir.
mkdir -p "$BUSYBOX_INSTALL_DIR"

# --- Download + Unpack BusyBox (if needed) ---
# Download handled by Makefile's download target using BUSYBOX_TARBALL path
# Ensure source is extracted into BUSYBOX_SRC_CACHE
if [ ! -f "$BUSYBOX_SRC_CACHE/Makefile" ]; then
    if [ ! -f "$BUSYBOX_TARBALL" ]; then
        echo "Error: BusyBox tarball '$BUSYBOX_TARBALL' not found. Please run 'make downloads' first." >&2
        exit 1
    fi
    echo "Extracting BusyBox source to $BUSYBOX_SRC_CACHE..."
    # Ensure the destination directory exists before extracting
    mkdir -p "$BUSYBOX_SRC_CACHE"
    # Use standard tar extraction with single -C
    tar -xf "$BUSYBOX_TARBALL" --strip-components=1 -C "$BUSYBOX_SRC_CACHE"
else
    echo "Using cached BusyBox source: $BUSYBOX_SRC_CACHE"
fi

# --- Configure, Build, and Install within the source directory ---
echo "Changing to BusyBox source directory: $BUSYBOX_SRC_CACHE"
cd "$BUSYBOX_SRC_CACHE"

echo "Configuring BusyBox for $KERNEL_ARCH using $BUSYBOX_CONFIG_FILE_ABS..."
# Copy the config file using its absolute path
cp "$BUSYBOX_CONFIG_FILE_ABS" .config
# Removed 'make olddefconfig' - let the main build handle it if necessary

# --- Build BusyBox ---
echo "Building BusyBox..."
# ARCH and CROSS_COMPILE are set via environment variables by the Makefile
make -j"$(nproc)"

# --- Install BusyBox ---
echo "Installing BusyBox to $BUSYBOX_INSTALL_DIR..."
# Clean install dir first to ensure freshness
rm -rf "$BUSYBOX_INSTALL_DIR"/*
# Install using the specified prefix (must be absolute for CONFIG_PREFIX)
# ARCH and CROSS_COMPILE are set via environment variables by the Makefile
make CONFIG_PREFIX="$BUSYBOX_INSTALL_DIR" install

# Go back to original directory (optional, good practice)
cd - > /dev/null

echo "BusyBox installed successfully to: $BUSYBOX_INSTALL_DIR"

# The Makefile will create the .stamp file upon successful exit of this script.
exit 0
