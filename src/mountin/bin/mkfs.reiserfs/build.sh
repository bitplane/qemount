#!/bin/bash
set -ex

cd /work
tar xf /host/build/sources/reiserfsprogs-3.6.27.tar.xz
cd reiserfsprogs-3.6.27

./configure --disable-shared CFLAGS="-D_GNU_SOURCE -static" LDFLAGS="-static"
make -j${BUILD_JOBS} -C include
make -j${BUILD_JOBS} -C lib
make -j${BUILD_JOBS} -C reiserfscore
make -j${BUILD_JOBS} -C mkreiserfs LDFLAGS="-static -all-static"

mkdir -p /host/build/bin/${TARGET_ARCH}-linux-gnu
cp mkreiserfs/mkreiserfs /host/build/bin/${TARGET_ARCH}-linux-gnu/mkfs.reiserfs
