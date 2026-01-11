#!/bin/bash
set -ex

cd /work
tar xf /host/build/sources/reiserfsprogs-3.6.27.tar.xz
cd reiserfsprogs-3.6.27

./configure CFLAGS="-D_GNU_SOURCE" LDFLAGS="-static"
make -j$(nproc)

mkdir -p /host/build/bin/linux-${HOST_ARCH}/reiserfsprogs
cp mkreiserfs/mkreiserfs /host/build/bin/linux-${HOST_ARCH}/reiserfsprogs/mkfs.reiserfs
