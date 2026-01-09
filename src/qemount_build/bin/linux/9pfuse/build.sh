#!/bin/sh
set -e

cd /work
tar -xf /host/build/sources/9pfuse-qemount-0.2.tar.gz
cd 9pfuse-qemount-0.2

meson setup build \
    --default-library=static \
    --prefer-static \
    -Dc_link_args="-static"

meson compile -C build

mkdir -p /host/build/bin/linux-${ARCH}/9pfuse
cp -v build/9pfuse /host/build/bin/linux-${ARCH}/9pfuse/
strip /host/build/bin/linux-${ARCH}/9pfuse/9pfuse
