#!/bin/bash
set -euo pipefail

# Parse arguments
KERNEL_VERSION="$1"
KERNEL_ARCH="$2"
BASE_KERNEL_CONFIG_FILE="$3"
FILESYSTEMS_CONFIG_FILE="$4"
CACHE_DIR=$(realpath "$5")
KERNEL_BUILD_DIR=$(realpath "$6")
CROSS_COMPILE_PREFIX="$7"

# Setup paths
KERNEL_TARBALL="$CACHE_DIR/linux-$KERNEL_VERSION.tar.xz"
KERNEL_SRC_CACHE="$CACHE_DIR/linux-$KERNEL_VERSION"
MERGE_SCRIPT="$KERNEL_SRC_CACHE/scripts/kconfig/merge_config.sh"

# Extract source if needed
if [ ! -f "$KERNEL_SRC_CACHE/Makefile" ]; then
    mkdir -p "$KERNEL_SRC_CACHE"
    tar -xf "$KERNEL_TARBALL" --strip-components=1 -C "$KERNEL_SRC_CACHE"
fi

# Create build directory
mkdir -p "$KERNEL_BUILD_DIR"

# Configure kernel
echo "Generating defconfig for $KERNEL_ARCH..."
make -C "$KERNEL_SRC_CACHE" O="$KERNEL_BUILD_DIR" defconfig

echo "Merging configs..."
"$MERGE_SCRIPT" -m -O "$KERNEL_BUILD_DIR" "$KERNEL_BUILD_DIR/.config" "$BASE_KERNEL_CONFIG_FILE"
"$MERGE_SCRIPT" -m -O "$KERNEL_BUILD_DIR" "$KERNEL_BUILD_DIR/.config" "$FILESYSTEMS_CONFIG_FILE"
make -C "$KERNEL_SRC_CACHE" O="$KERNEL_BUILD_DIR" olddefconfig

# Build kernel
echo "Building kernel..."
make -C "$KERNEL_SRC_CACHE" O="$KERNEL_BUILD_DIR" -j"$(nproc)"

exit 0