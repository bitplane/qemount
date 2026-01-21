#!/bin/sh
set -e

NBARCH=$(cat /tmp/nbarch)
NBKERNARCH=$(cat /tmp/nbkernarch)

cd /usr/src

# Copy kernel config
cp /QEMOUNT /usr/src/sys/arch/$NBKERNARCH/conf/QEMOUNT

# Build the kernel
./build.sh -O /usr/obj -T /usr/tools -U -u -j${JOBS} -m $NBARCH kernel=QEMOUNT

# Copy unstripped kernel (needed for mdsetimage)
mkdir -p /host/build/bin/qemu/${ARCH}-netbsd/10.0/kernel
cp /usr/obj/sys/arch/$NBKERNARCH/compile/QEMOUNT/netbsd.gdb \
   /host/build/bin/qemu/${ARCH}-netbsd/10.0/kernel/netbsd.gdb
