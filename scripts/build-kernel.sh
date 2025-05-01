#!/bin/bash
set -eux

KERNEL_VERSION=$1
ARCH=$2
KERNEL_DIR=$3
KERNEL_IMAGE=$4

KERNEL_TARBALL="linux-${KERNEL_VERSION}.tar.xz"
KERNEL_SRC_DIR="${KERNEL_DIR}/linux-${KERNEL_VERSION}"
CONFIG_PATH="config/kernel/${ARCH}/minimal.config"

mkdir -p "$KERNEL_DIR"
pushd "$KERNEL_DIR"  # Now in kernel build directory

# Download kernel if missing
if [ ! -f "$KERNEL_TARBALL" ]; then
    wget "https://cdn.kernel.org/pub/linux/kernel/v6.x/${KERNEL_TARBALL}"
fi

# Extract source if needed
if [ ! -d "$KERNEL_SRC_DIR" ]; then
    tar -xf "$KERNEL_TARBALL"
fi

pushd "$KERNEL_SRC_DIR"  # Now in kernel source dir

cp "$OLDPWD/../../../$CONFIG_PATH" .config
make olddefconfig
make -j"$(nproc)" ARCH="$ARCH"

popd  # back to KERNEL_DIR
popd  # back to original PWD
