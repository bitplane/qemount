#!/bin/bash
set -ex

cd /work
tar xf /host/build/sources/reiserfsprogs-3.6.27.tar.xz
cd reiserfsprogs-3.6.27

./configure --disable-shared CFLAGS="-D_GNU_SOURCE -static" LDFLAGS="-static"
make -j${JOBS} -C include
make -j${JOBS} -C lib
make -j${JOBS} -C reiserfscore
make -j${JOBS} -C mkreiserfs LDFLAGS="-static -all-static"

mkdir -p /host/build/bin/${HOST_ARCH}-linux-gnu
cp mkreiserfs/mkreiserfs /host/build/bin/${HOST_ARCH}-linux-gnu/mkfs.reiserfs
