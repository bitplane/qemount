#!/bin/bash
#
# guest/linux-6.11/scripts/build-kernel.sh
#
# Builds the Linux kernel image and modules into a specified build directory.
# Relies on ARCH and CROSS_COMPILE environment variables being set by the calling Makefile.
#
# Usage:
# ./build-kernel.sh <KERNEL_VERSION> <KERNEL_ARCH> <KERNEL_CONFIG_FILE> \
#                   <CACHE_DIR> <KERNEL_BUILD_DIR> <CROSS_COMPILE_PREFIX>

set -euo pipefail

# --- Argument Parsing ---
if [ "$#" -ne 6 ]; then
    echo "Usage: $0 <KERNEL_VERSION> <KERNEL_ARCH> <KERNEL_CONFIG_FILE> <CACHE_DIR> <KERNEL_BUILD_DIR> <CROSS_COMPILE_PREFIX>"
    exit 1
fi

KERNEL_VERSION="$1"
KERNEL_ARCH="$2"       # e.g., x86_64, arm64 (Passed as ARCH env var too)
KERNEL_CONFIG_FILE="$3" # Path relative to guest Makefile dir (e.g., config/kernel.x86_64.config)
CACHE_DIR_REL="$4"         # Relative or absolute path to cache root
KERNEL_BUILD_DIR_REL="$5"  # Relative or absolute path for kernel build artifacts (O= target)
CROSS_COMPILE_PREFIX="$6" # e.g., aarch64-linux-gnu- (Passed as CROSS_COMPILE env var too)

# --- Resolve Paths ---
# Convert potentially relative paths passed from makefile to absolute paths
CACHE_DIR=$(realpath "$CACHE_DIR_REL")
KERNEL_BUILD_DIR=$(realpath "$KERNEL_BUILD_DIR_REL")
# KERNEL_CONFIG_FILE is relative to the Makefile dir, resolve it from there if needed,
# but assuming it's called from guest/linux-6.11, the relative path should work for cp.
# If running script standalone, adjust this:
# KERNEL_CONFIG_FILE_ABS=$(realpath "$KERNEL_CONFIG_FILE") # Use this if needed below

# --- Path Setup ---
# Use CACHE_DIR for downloads and source extraction
KERNEL_TARBALL="$CACHE_DIR/linux-$KERNEL_VERSION.tar.xz"
KERNEL_SRC_CACHE="$CACHE_DIR/linux-$KERNEL_VERSION" # Extracted source lives here

# --- Ensure Config File Exists ---
# Note: KERNEL_CONFIG_FILE is relative to the Makefile's CWD (guest/linux-6.11)
if [ ! -f "$KERNEL_CONFIG_FILE" ]; then
    echo "Error: Missing kernel config file: '$KERNEL_CONFIG_FILE'" >&2
    exit 1
fi

# --- Ensure Build Directory Exists ---
mkdir -p "$KERNEL_BUILD_DIR"

# --- Download + Unpack Kernel (if needed) ---
# Download handled by Makefile's download target using KERNEL_TARBALL path
# Ensure source is extracted into KERNEL_SRC_CACHE
if [ ! -f "$KERNEL_SRC_CACHE/Makefile" ]; then
    if [ ! -f "$KERNEL_TARBALL" ]; then
        echo "Error: Kernel tarball '$KERNEL_TARBALL' not found. Please run 'make downloads' first." >&2
        exit 1
    fi
    echo "Extracting Kernel source to $KERNEL_SRC_CACHE..."
    mkdir -p "$KERNEL_SRC_CACHE"
    # Ensure source cache dir exists before tar tries to cd into it via --strip-components
    mkdir -p "$(dirname "$KERNEL_SRC_CACHE")"
    tar -xf "$KERNEL_TARBALL" -C "$(dirname "$KERNEL_SRC_CACHE")" --strip-components=1 -C "$KERNEL_SRC_CACHE"
else
    echo "Using cached kernel source: $KERNEL_SRC_CACHE"
fi

# --- Configure Kernel ---
echo "Configuring Kernel for $KERNEL_ARCH..."
# Copy the specific config file to the build directory (.config)
cp "$KERNEL_CONFIG_FILE" "$KERNEL_BUILD_DIR/.config"
# Run olddefconfig using the source dir and the build dir (O=)
# ARCH and CROSS_COMPILE are set via environment variables by the Makefile
# Use absolute paths for source and output directories for make -C
make -C "$KERNEL_SRC_CACHE" O="$KERNEL_BUILD_DIR" olddefconfig

# --- Build Kernel Image and Modules ---
echo "Building Kernel Image and Modules in $KERNEL_BUILD_DIR..."
# ARCH and CROSS_COMPILE are set via environment variables by the Makefile
# Use absolute paths for source and output directories for make -C
make -C "$KERNEL_SRC_CACHE" O="$KERNEL_BUILD_DIR" -j"$(nproc)" all modules

# --- Install Headers (Optional, if needed elsewhere) ---
# KERNEL_HEADERS_INSTALL_DIR="$KERNEL_BUILD_DIR/headers"
# echo "Installing Kernel Headers to $KERNEL_HEADERS_INSTALL_DIR..."
# make -C "$KERNEL_SRC_CACHE" O="$KERNEL_BUILD_DIR" headers_install INSTALL_HDR_PATH="$KERNEL_HEADERS_INSTALL_DIR"

echo "Kernel build artifacts generated in: $KERNEL_BUILD_DIR"
echo "(Image is at $KERNEL_BUILD_DIR/arch/$KERNEL_ARCH/boot/...)"
echo "(Modules are under $KERNEL_BUILD_DIR/)"

# The Makefile will create the .kernel_built stamp file upon successful exit of this script.
exit 0
