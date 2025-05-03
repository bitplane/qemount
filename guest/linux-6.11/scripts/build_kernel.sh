#!/bin/bash
#
# guest/linux-6.11/scripts/build-kernel.sh
#
# Builds the Linux kernel image using a layered configuration approach:
# 1. Starts with 'make defconfig' for the architecture.
# 2. Merges a base configuration file (e.g., kernel.base.config).
# 3. Merges a filesystem-specific configuration file (e.g., filesystems.config).
# 4. Finalizes with 'make olddefconfig'.
# 5. Builds the kernel (assuming built-in drivers, 'make all' is sufficient).
#
# Relies on ARCH and CROSS_COMPILE environment variables being set by the calling Makefile.
#
# Usage:
# ./build-kernel.sh <KERNEL_VERSION> <KERNEL_ARCH> <BASE_KERNEL_CONFIG_FILE> <FILESYSTEMS_CONFIG_FILE> \
#                   <CACHE_DIR> <KERNEL_BUILD_DIR> <CROSS_COMPILE_PREFIX>

set -euo pipefail

# --- Argument Parsing ---
if [ "$#" -ne 7 ]; then
    # Updated Usage message to reflect the 4th argument purpose
    echo "Usage: $0 <KERNEL_VERSION> <KERNEL_ARCH> <BASE_KERNEL_CONFIG_FILE> <FILESYSTEMS_CONFIG_FILE> <CACHE_DIR> <KERNEL_BUILD_DIR> <CROSS_COMPILE_PREFIX>"
    exit 1
fi

KERNEL_VERSION="$1"
KERNEL_ARCH="$2"                 # e.g., x86_64, arm64 (Passed as ARCH env var too)
BASE_KERNEL_CONFIG_FILE="$3"     # Path to the base config (e.g., config/kernel.base.config)
# Updated variable name for the 4th argument
FILESYSTEMS_CONFIG_FILE="$4" # Path to filesystem-specific settings (e.g., config/filesystems.config)
CACHE_DIR_REL="$5"               # Relative or absolute path to cache root
KERNEL_BUILD_DIR_REL="$6"        # Relative or absolute path for kernel build artifacts (O= target)
CROSS_COMPILE_PREFIX="$7"        # e.g., aarch64-linux-gnu- (Passed as CROSS_COMPILE env var too)

# --- Resolve Paths ---
# Convert potentially relative paths passed from makefile to absolute paths
CACHE_DIR=$(realpath "$CACHE_DIR_REL")
KERNEL_BUILD_DIR=$(realpath "$KERNEL_BUILD_DIR_REL")
# Config files are relative to the Makefile's CWD (guest/linux-6.11)
# Resolve them here for clarity and robustness
BASE_KERNEL_CONFIG_FILE_ABS=$(realpath "$BASE_KERNEL_CONFIG_FILE")
# Updated variable name for resolving the 4th argument's path
FILESYSTEMS_CONFIG_FILE_ABS=$(realpath "$FILESYSTEMS_CONFIG_FILE")


# --- Path Setup ---
# Use CACHE_DIR for downloads and source extraction
KERNEL_TARBALL="$CACHE_DIR/linux-$KERNEL_VERSION.tar.xz"
KERNEL_SRC_CACHE="$CACHE_DIR/linux-$KERNEL_VERSION" # Extracted source lives here
MERGE_SCRIPT="$KERNEL_SRC_CACHE/scripts/kconfig/merge_config.sh"

# --- Ensure Config Files Exist ---
if [ ! -f "$BASE_KERNEL_CONFIG_FILE_ABS" ]; then
    echo "Error: Missing base kernel config file: '$BASE_KERNEL_CONFIG_FILE_ABS' (Resolved from '$BASE_KERNEL_CONFIG_FILE')" >&2
    exit 1
fi
# Updated check for the 4th argument file
if [ ! -f "$FILESYSTEMS_CONFIG_FILE_ABS" ]; then
    echo "Error: Missing filesystems config file: '$FILESYSTEMS_CONFIG_FILE_ABS' (Resolved from '$FILESYSTEMS_CONFIG_FILE')" >&2
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
# 1. Generate base config in the build directory
echo "Generating base defconfig for $KERNEL_ARCH into $KERNEL_BUILD_DIR..."
make -C "$KERNEL_SRC_CACHE" O="$KERNEL_BUILD_DIR" defconfig

# Check if defconfig succeeded
if [ ! -f "$KERNEL_BUILD_DIR/.config" ]; then
    echo "Error: make defconfig failed to create .config in $KERNEL_BUILD_DIR"
    exit 1
fi

# 2. Merge the base configuration file
echo "Merging base config '$BASE_KERNEL_CONFIG_FILE_ABS'..."
if ! "$MERGE_SCRIPT" -m -O "$KERNEL_BUILD_DIR" "$KERNEL_BUILD_DIR/.config" "$BASE_KERNEL_CONFIG_FILE_ABS"; then
    echo "Error: merge_config.sh failed for base config"
    exit 1
fi

# 3. Merge the filesystem-specific configuration file
# Updated log message and variable name for the 4th argument merge
echo "Merging filesystems config '$FILESYSTEMS_CONFIG_FILE_ABS'..."
if ! "$MERGE_SCRIPT" -m -O "$KERNEL_BUILD_DIR" "$KERNEL_BUILD_DIR/.config" "$FILESYSTEMS_CONFIG_FILE_ABS"; then
    echo "Error: merge_config.sh failed for filesystems config"
    exit 1
fi

# 4. Finalize (resolve dependencies, set defaults for new options)
echo "Running olddefconfig on merged config..."
make -C "$KERNEL_SRC_CACHE" O="$KERNEL_BUILD_DIR" olddefconfig

# --- Build Kernel Image ---
echo "Building Kernel Image in $KERNEL_BUILD_DIR (expecting built-in drivers)..."
# ARCH and CROSS_COMPILE are set via environment variables by the Makefile
# Use absolute paths for source and output directories for make -C
# Since we expect drivers built-in, 'make all' or just 'make' is sufficient.
# No need for the separate 'modules' target anymore.
make -C "$KERNEL_SRC_CACHE" O="$KERNEL_BUILD_DIR" -j"$(nproc)"

echo "Kernel build artifacts generated in: $KERNEL_BUILD_DIR"
echo "(Image should be at $KERNEL_BUILD_DIR/arch/$KERNEL_ARCH/boot/...)"

# The Makefile will create the .kernel_built stamp file upon successful exit of this script.
exit 0
