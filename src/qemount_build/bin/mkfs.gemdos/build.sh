#!/bin/sh
set -e

cd /work
gcc -static -o mkfs.gemdos mkfs.gemdos.c

mkdir -p /host/build/bin/${HOST_ARCH}-linux-musl
cp -v mkfs.gemdos /host/build/bin/${HOST_ARCH}-linux-musl/
