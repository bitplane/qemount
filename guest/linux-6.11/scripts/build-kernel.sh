#!/bin/bash
set -eux

KERNEL_VERSION=$1
ARCH=$2
ROOT=$(cd "$(dirname "$0")/.." && pwd)

KERNEL_DIR="$ROOT/build/linux"
KERNEL_TARBALL="$KERNEL_DIR/linux-$KERNEL_VERSION.tar.xz"
KERNEL_SRC="$KERNEL_DIR/linux-$KERNEL_VERSION"
KERNEL_HEADERS="$KERNEL_DIR/headers"
KERNEL_CONFIG="$ROOT/config/kernel/$ARCH/minimal.config"

# Ensure the config file exists
[ -f "$KERNEL_CONFIG" ] || {
    echo "Missing kernel config: $KERNEL_CONFIG" >&2
    exit 1
}

# Download + unpack kernel
mkdir -p "$KERNEL_DIR"
[ -f "$KERNEL_TARBALL" ] || wget -O "$KERNEL_TARBALL" "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$KERNEL_VERSION.tar.xz"
[ -d "$KERNEL_SRC" ] || tar -xf "$KERNEL_TARBALL" -C "$KERNEL_DIR"

# Use the repo config without touching it
cp "$KERNEL_CONFIG" "$KERNEL_SRC/.config"

# Build kernel and headers
make -C "$KERNEL_SRC" ARCH="$ARCH" O="$KERNEL_SRC" olddefconfig
make -C "$KERNEL_SRC" ARCH="$ARCH" O="$KERNEL_SRC" -j"$(nproc)"
make -C "$KERNEL_SRC" ARCH="$ARCH" O="$KERNEL_SRC" headers_install INSTALL_HDR_PATH="$KERNEL_HEADERS"
