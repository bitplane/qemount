#!/bin/sh
set -e

cd /work
gcc -static -o mkfs.tux3 mkfs.tux3.c

mkdir -p /host/build/bin/${HOST_ARCH}-linux-musl
cp -v mkfs.tux3 /host/build/bin/${HOST_ARCH}-linux-musl/
