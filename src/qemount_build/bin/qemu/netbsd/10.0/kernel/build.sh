#!/bin/sh
set -eu

NBARCH=$(cat /tmp/nbarch)
NBMACHINEARCH=$(cat /tmp/nbmachinearch)
NBKERNARCH=$(cat /tmp/nbkernarch)
SOURCE_HASH=$(sha256sum \
    /host/build/sources/netbsd-10.0-src.tgz \
    /host/build/sources/netbsd-10.0-syssrc.tgz \
    /host/build/sources/netbsd-10.0-sharesrc.tgz \
    /host/build/sources/netbsd-10.0-gnusrc.tgz \
    | sha256sum | cut -d ' ' -f 1)
OBJ_DIR=/host/build/cache/netbsd/${ARCH}/10.0/kernel-v1/${SOURCE_HASH}/obj

cd /usr/src

# Copy kernel config
cp /QEMOUNT /usr/src/sys/arch/$NBKERNARCH/conf/QEMOUNT

# Build the kernel
mkdir -p "$OBJ_DIR"
./build.sh -O "$OBJ_DIR" -T /usr/tools -U -u -j"${JOBS}" \
    -m "$NBARCH" -a "$NBMACHINEARCH" kernel=QEMOUNT

# Copy unstripped kernel (needed for mdsetimage)
mkdir -p /host/build/bin/qemu/${ARCH}-netbsd/10.0/kernel
cp "$OBJ_DIR/sys/arch/$NBKERNARCH/compile/QEMOUNT/netbsd.gdb" \
   /host/build/bin/qemu/${ARCH}-netbsd/10.0/kernel/netbsd.gdb
