#!/bin/bash
set -ex

cd /work

tar xf /host/build/sources/mkfs-tux3-2015.06.01.tar.gz
cd mkfs-tux3-2015.06.01

# The Makefile uses $(CC) $(CFLAGS) for both compile and link without
# $(LDFLAGS), so wrap CC with -static to get a static binary.
make -j$(nproc) CC="gcc -static"

mkdir -p /host/build/bin/${HOST_ARCH}-linux-gnu
cp -v mkfs.tux3 /host/build/bin/${HOST_ARCH}-linux-gnu/
strip /host/build/bin/${HOST_ARCH}-linux-gnu/mkfs.tux3
