#!/bin/sh
set -e

BINDIR="/host/build/bin/${OUTPUT_ARCH}-linux-${ENV}"
ROOT="/work/root"
rm -rf "$ROOT"
cp -a /root "$ROOT"
mkdir -p "$ROOT/dev" "$ROOT/mnt" "$ROOT/proc" "$ROOT/sys" "$ROOT/tmp"
mkdir -p "$ROOT/bin"
cp -v "$BINDIR/busybox" "$ROOT/bin/"
cp -v "$BINDIR/socat" "$ROOT/bin/"
cp -v "$BINDIR/dropbearmulti" "$ROOT/bin/"
cd "$ROOT/bin"
for cmd in $(./busybox --list); do
    [ ! -e "$cmd" ] && ln -s busybox "$cmd"
done
for cmd in dropbear dbclient dropbearkey dropbearconvert scp; do
    [ ! -e "$cmd" ] && ln -s dropbearmulti "$cmd"
done
cd /work
SIZE=$(du -sm "$ROOT" | cut -f1)
IMG_SIZE=$(( SIZE + 4 ))M
truncate -s "$IMG_SIZE" /work/rootfs.img
mke2fs -t ext2 -d "$ROOT" /work/rootfs.img

# Copy to output
mkdir -p /host/build/guest/${OUTPUT_ARCH}-linux/base
cp /work/rootfs.img /host/build/guest/${OUTPUT_ARCH}-linux/base/
