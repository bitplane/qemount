#!/bin/bash
set -eux

VERSION=$1
ARCH=$2
CONFIG_PATH=$(realpath $3)
SRC_DIR=$(realpath $4)
TARBALL=$(realpath $5)
INSTALL_DIR=$(realpath $SRC_DIR/_install)

mkdir -p "$(dirname "$SRC_DIR")"
cd "$(dirname "$SRC_DIR")"

if [ ! -d "$SRC_DIR" ]; then
    tar -xf "$TARBALL"
fi

pushd "$SRC_DIR"

make distclean || true
cp "$CONFIG_PATH" .config

make -j"$(nproc)"
make CONFIG_PREFIX="$INSTALL_DIR" install

popd
