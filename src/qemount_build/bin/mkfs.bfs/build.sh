#!/bin/bash
set -e

CRATE=mkfs-bfs
VERSION=0.1.0
BIN_DOT=mkfs.bfs

cd /work
tar xf /host/build/sources/${CRATE}-${VERSION}.tar.gz
cd ${CRATE}-${VERSION}

cargo zigbuild --release --locked \
    --target ${HOST_ARCH}-unknown-linux-musl

OUT=/host/build/bin/${HOST_ARCH}-linux-musl
mkdir -p ${OUT}
TARGET=${CARGO_TARGET_DIR:-target}
cp -v ${TARGET}/${HOST_ARCH}-unknown-linux-musl/release/${CRATE} ${OUT}/${BIN_DOT}
