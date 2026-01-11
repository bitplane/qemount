#!/bin/sh
set -e

cd /work
tar -xf /host/build/sources/socat-1.7.4.4.tar.gz
cd socat-1.7.4.4

./configure --enable-static --disable-shared
make -j${JOBS}
strip socat || true

mkdir -p /host/build/bin/linux-${ARCH}/socat
cp -v socat /host/build/bin/linux-${ARCH}/socat/
