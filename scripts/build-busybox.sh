#!/bin/bash
set -eux

VERSION=$1
ARCH=$2
CONFIG_PATH=$3
SRC_DIR=$4
TARBALL=$(dirname "$SRC_DIR")/busybox-$VERSION.tar.bz2
INSTALL_DIR=$SRC_DIR/_install

mkdir -p "$(dirname "$SRC_DIR")"
cd "$(dirname "$SRC_DIR")"

if [ ! -d "$SRC_DIR" ]; then
    tar -xf "$TARBALL"
fi

pushd "$SRC_DIR"

make distclean || true
cp "$OLDPWD/$CONFIG_PATH" .config

make -j"$(nproc)"
make CONFIG_PREFIX="$INSTALL_DIR" install

popd
