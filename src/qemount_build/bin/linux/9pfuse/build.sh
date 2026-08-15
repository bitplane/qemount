#!/bin/sh
set -e

cd /work
tar -xf /host/build/sources/9pfuse-mountin-2026-08-15.tar.gz
cd 9pfuse-mountin-2026-08-15

meson setup build \
    --default-library=static \
    --prefer-static \
    -Dc_link_args="-static"

meson compile -C build

mkdir -p /host/build/bin/${OUTPUT_ARCH}-linux-${ENV}
cp -v build/9pfuse /host/build/bin/${OUTPUT_ARCH}-linux-${ENV}/
strip /host/build/bin/${OUTPUT_ARCH}-linux-${ENV}/9pfuse
