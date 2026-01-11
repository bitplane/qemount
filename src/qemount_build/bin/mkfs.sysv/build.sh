#!/bin/sh
set -e

cd /work
gcc -static -o mkfs.sysv mkfs.sysv.c

mkdir -p /host/build/bin/linux-${HOST_ARCH}/mkfs.sysv
cp -v mkfs.sysv /host/build/bin/linux-${HOST_ARCH}/mkfs.sysv/mkfs.sysv
