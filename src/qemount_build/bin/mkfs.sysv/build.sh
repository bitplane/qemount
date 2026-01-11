#!/bin/sh
set -e

cd /work
gcc -static -o mkfs.sysv mkfs.sysv.c

mkdir -p /host/build/bin
cp -v mkfs.sysv /host/build/bin/mkfs.sysv-${HOST_ARCH}
