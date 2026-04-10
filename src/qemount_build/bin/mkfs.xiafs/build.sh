#!/bin/sh
set -e

cd /work
gcc -static -o mkfs.xiafs mkfs.xiafs.c

mkdir -p /host/build/bin/${HOST_ARCH}-linux-musl
cp -v mkfs.xiafs /host/build/bin/${HOST_ARCH}-linux-musl/
