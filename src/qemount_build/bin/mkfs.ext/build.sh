#!/bin/sh
set -e

cd /work
gcc -static -o mkfs.ext mkfs.ext.c

mkdir -p /host/build/bin/${HOST_ARCH}-linux-musl
cp -v mkfs.ext /host/build/bin/${HOST_ARCH}-linux-musl/
