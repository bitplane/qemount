#!/bin/sh
set -e

cd /work
gcc -static -o mkfs.bfs mkfs.bfs.c

mkdir -p /host/build/bin/${HOST_ARCH}-linux-musl
cp -v mkfs.bfs /host/build/bin/${HOST_ARCH}-linux-musl/
