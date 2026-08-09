#!/bin/sh
set -eu

NBARCH=$(cat /tmp/nbarch)
NBMACHINEARCH=$(cat /tmp/nbmachinearch)
NBKERNARCH=$(cat /tmp/nbkernarch)
OBJ_DIR=$QEMOUNT_CACHE_DIR/obj

cd /usr/src

# The machine configurations are intentionally separate; only the surrounding
# build pipeline is architecture-independent.
case "$NBKERNARCH" in
    amd64) CONFIG=/QEMOUNT ;;
    evbarm) CONFIG=/QEMOUNT.evbarm ;;
    *) echo "Unsupported NetBSD kernel architecture: $NBKERNARCH" >&2; exit 1 ;;
esac
cp "$CONFIG" "/usr/src/sys/arch/$NBKERNARCH/conf/QEMOUNT"

# Build the kernel
mkdir -p "$OBJ_DIR"
./build.sh -O "$OBJ_DIR" -T /usr/tools -U -u -j"${JOBS}" \
    -m "$NBARCH" -a "$NBMACHINEARCH" kernel=QEMOUNT

# Copy unstripped kernel (needed for mdsetimage)
OUTPUT_DIR="/host/build/bin/qemu/${OUTPUT_ARCH}-netbsd/10.0/kernel"
mkdir -p "$OUTPUT_DIR"
cp "$OBJ_DIR/sys/arch/$NBKERNARCH/compile/QEMOUNT/netbsd.gdb" \
   "$OUTPUT_DIR/netbsd.gdb"
