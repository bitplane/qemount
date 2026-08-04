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
CACHE_DIR=/host/build/cache/netbsd/${BUILD_PLATFORM}/${OUTPUT_ARCH}/10.0
OBJ_DIR=$CACHE_DIR/kernel-v1/${SOURCE_HASH}/obj

cd /usr/src

# The machine configurations are intentionally separate; only the surrounding
# build pipeline is architecture-independent.
case "$NBKERNARCH" in
    amd64) CONFIG=/QEMOUNT ;;
    evbarm) CONFIG=/QEMOUNT.evbarm ;;
    *) echo "Unsupported NetBSD kernel architecture: $NBKERNARCH" >&2; exit 1 ;;
esac
cp "$CONFIG" /usr/src/sys/arch/$NBKERNARCH/conf/QEMOUNT

# Build the kernel
mkdir -p "$OBJ_DIR"
./build.sh -O "$OBJ_DIR" -T /usr/tools -U -u -j"${JOBS}" \
    -m "$NBARCH" -a "$NBMACHINEARCH" kernel=QEMOUNT

# Copy unstripped kernel (needed for mdsetimage)
mkdir -p /host/build/bin/qemu/${OUTPUT_ARCH}-netbsd/10.0/kernel
cp "$OBJ_DIR/sys/arch/$NBKERNARCH/compile/QEMOUNT/netbsd.gdb" \
   /host/build/bin/qemu/${OUTPUT_ARCH}-netbsd/10.0/kernel/netbsd.gdb
