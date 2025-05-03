#!/bin/bash
set -euo pipefail

# Parse arguments
BUSYBOX_VERSION="$1"
KERNEL_ARCH="$2"
BUSYBOX_CONFIG_FILE=$(readlink -f "$3")
CACHE_DIR=$(readlink -f "$4")
BUSYBOX_INSTALL_DIR=$(readlink -f "$5")
CROSS_COMPILE_PREFIX="$6"
MERGE_CONFIG_SCRIPT=$(readlink -f "$7")  # Get absolute path to the script

BUSYBOX_SRC_DIR="$CACHE_DIR/busybox-$BUSYBOX_VERSION"

echo "Building BusyBox in $BUSYBOX_SRC_DIR using config $BUSYBOX_CONFIG_FILE"
cd "$BUSYBOX_SRC_DIR"

# Start with defconfig
echo "Starting with defconfig..."
make ARCH="$KERNEL_ARCH" CROSS_COMPILE="$CROSS_COMPILE_PREFIX" defconfig

# Merge configurations using the provided script with absolute paths
echo "Merging configurations..."
python3 "$MERGE_CONFIG_SCRIPT" ".config" "$BUSYBOX_CONFIG_FILE" ".config.new"
cp .config.new .config

# Run defconfig to handle dependencies
yes "" | make ARCH="$KERNEL_ARCH" CROSS_COMPILE="$CROSS_COMPILE_PREFIX" oldconfig || true

echo "Building BusyBox..."
make ARCH="$KERNEL_ARCH" CROSS_COMPILE="$CROSS_COMPILE_PREFIX" -j"$(nproc)"

echo "Installing BusyBox to $BUSYBOX_INSTALL_DIR"
rm -rf "$BUSYBOX_INSTALL_DIR"
mkdir -p "$BUSYBOX_INSTALL_DIR"
make ARCH="$KERNEL_ARCH" CROSS_COMPILE="$CROSS_COMPILE_PREFIX" CONFIG_PREFIX="$BUSYBOX_INSTALL_DIR" install

echo "BusyBox built and installed successfully!"
