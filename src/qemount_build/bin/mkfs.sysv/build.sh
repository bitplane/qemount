#!/bin/sh
set -e

cd /work
gcc -static -o mkfs.sysv mkfs.sysv.c

mkdir -p /host/build/bin/${HOST_ARCH}-linux-musl
cp -v mkfs.sysv /host/build/bin/${HOST_ARCH}-linux-musl/
