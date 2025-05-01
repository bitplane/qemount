#!/bin/bash
set -eux

VERSION="$1"
ARCH="$2"
CONFIG_PATH="$3"
CONFIG_PATH=$(realpath "$CONFIG_PATH")
SRC_DIR="$4"

TARBALL="build/initramfs/busybox-$VERSION.tar.bz2"
INSTALL_DIR="$SRC_DIR/_install"

# Extract if missing
if [ ! -d "$SRC_DIR" ]; then
    tar -xf "$TARBALL" -C "$(dirname "$SRC_DIR")"
fi

pushd "$SRC_DIR"
make distclean || true
cp "$CONFIG_PATH" .config
make -j"$(nproc)"
make CONFIG_PREFIX="$INSTALL_DIR" install
popd
