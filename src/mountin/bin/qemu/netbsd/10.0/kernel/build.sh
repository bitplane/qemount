#!/bin/sh
set -eu

NBARCH=$(cat /tmp/nbarch)
NBMACHINEARCH=$(cat /tmp/nbmachinearch)
NBKERNARCH=$(cat /tmp/nbkernarch)
OBJ_DIR=$MOUNTIN_CACHE_DIR/obj
SOURCE_DIR=$MOUNTIN_CACHE_DIR/source
RAMDISK_DIR="/host/build/bin/qemu/${OUTPUT_ARCH}-netbsd/10.0/rootfs"

if [ ! -f "$SOURCE_DIR/.extracted" ]; then
    rm -rf "$SOURCE_DIR"
    mkdir -p "$SOURCE_DIR"
    tar -xzf /host/build/sources/netbsd-10.0-syssrc.tgz -C "$SOURCE_DIR"
    touch "$SOURCE_DIR/.extracted"
fi

SYS_DIR="$SOURCE_DIR/usr/src/sys"

# The machine configurations are intentionally separate; only the surrounding
# build pipeline is architecture-independent.
case "$NBKERNARCH" in
    amd64) CONFIG=/MOUNTIN ;;
    evbarm) CONFIG=/MOUNTIN.evbarm ;;
    *) echo "Unsupported NetBSD kernel architecture: $NBKERNARCH" >&2; exit 1 ;;
esac
RAMDISK_SECTORS=$(cat "$RAMDISK_DIR/ramdisk.sectors")
sed "s/@RAMDISK_SECTORS@/$RAMDISK_SECTORS/g" "$CONFIG" \
    > "$MOUNTIN_CACHE_DIR/MOUNTIN"

mkdir -p "$OBJ_DIR"
/usr/tools/bin/nbconfig -s "$SYS_DIR" -b "$OBJ_DIR" \
    "$MOUNTIN_CACHE_DIR/MOUNTIN"
/usr/tools/bin/nbmake-"$NBARCH" -C "$OBJ_DIR" -j"${JOBS}" \
    NETBSDSRCDIR="$SOURCE_DIR/usr/src" depend all

# Copy unstripped kernel (needed for mdsetimage)
OUTPUT_DIR="/host/build/bin/qemu/${OUTPUT_ARCH}-netbsd/10.0/kernel"
mkdir -p "$OUTPUT_DIR"
cp "$OBJ_DIR/netbsd" "$OUTPUT_DIR/netbsd.gdb"
