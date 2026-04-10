#!/bin/sh
set -e

cd /work
gcc -static -o mkfs.mfs mkfs.mfs.c

mkdir -p /host/build/bin/${HOST_ARCH}-linux-musl
cp -v mkfs.mfs /host/build/bin/${HOST_ARCH}-linux-musl/
