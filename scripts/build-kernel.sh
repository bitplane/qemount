#!/bin/bash
set -eux

KERNEL_VERSION=$1
ARCH=$2
KERNEL_DIR=$3
KERNEL_IMAGE=$4

mkdir -p "$KERNEL_DIR"
cd "$KERNEL_DIR"

KERNEL_TAR="linux-${KERNEL_VERSION}.tar.xz"
KERNEL_SRC="linux-${KERNEL_VERSION}"

# Download kernel
if [ ! -f "$KERNEL_TAR" ]; then
    wget "https://cdn.kernel.org/pub/linux/kernel/v6.x/$KERNEL_TAR"
fi

# Extract if needed
if [ ! -d "$KERNEL_SRC" ]; then
    tar xf "$KERNEL_TAR"
fi

cd "$KERNEL_SRC"
CONFIG_PATH=../../../config/kernel/$ARCH/minimal.config
cp "$CONFIG_PATH" .config
make olddefconfig
make -j"$(nproc)" ARCH=$ARCH
