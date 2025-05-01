#!/bin/bash
set -eux

# Config
KERNEL_VERSION=$1
ARCH=$2
KERNEL_DIR=$3        # e.g. build/linux
KERNEL_IMAGE=$4      # e.g. build/linux/linux-6.5/arch/x86_64/boot/bzImage

# Derived paths
KERNEL_TARBALL="$KERNEL_DIR/linux-$KERNEL_VERSION.tar.xz"
KERNEL_SRC="$KERNEL_DIR/linux-$KERNEL_VERSION"
KERNEL_HEADERS="$KERNEL_DIR/headers"
KERNEL_CONFIG="config/kernel/$ARCH/minimal.config"

# Fetch and unpack
mkdir -p "$KERNEL_DIR"
if [ ! -f "$KERNEL_TARBALL" ]; then
    wget -O "$KERNEL_TARBALL" "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$KERNEL_VERSION.tar.xz"
fi
if [ ! -d "$KERNEL_SRC" ]; then
    tar -xf "$KERNEL_TARBALL" -C "$KERNEL_DIR"
fi

# Build kernel
pushd "$KERNEL_SRC"
cp "$(realpath "$OLDPWD/$KERNEL_CONFIG")" .config
make olddefconfig ARCH="$ARCH"
make -j"$(nproc)" ARCH="$ARCH"

# Build headers
mkdir -p "$KERNEL_HEADERS"
make headers_install ARCH="$ARCH" INSTALL_HDR_PATH="$(realpath "$KERNEL_HEADERS")"
popd
