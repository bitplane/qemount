#!/bin/sh
set -e

BINDIR="/host/build/bin/linux-${ARCH}"
ROOT="/work/root"

# Start with overlay from image
cp -a /root "$ROOT"

# Copy binaries
mkdir -p "$ROOT/bin"
cp -v "$BINDIR/busybox/busybox" "$ROOT/bin/"
cp -v "$BINDIR/simple9p/simple9p" "$ROOT/bin/"
cp -v "$BINDIR/socat/socat" "$ROOT/bin/"
cp -v "$BINDIR/dropbear/dropbearmulti" "$ROOT/bin/"

# Create busybox symlinks dynamically
cd "$ROOT/bin"
for cmd in $(./busybox --list); do
    [ ! -e "$cmd" ] && ln -s busybox "$cmd"
done

# Create dropbear symlinks
for cmd in dropbear dbclient dropbearkey dropbearconvert scp; do
    [ ! -e "$cmd" ] && ln -s dropbearmulti "$cmd"
done

cd /work

# Calculate size and create ext2 image
SIZE=$(du -sm "$ROOT" | cut -f1)
IMG_SIZE=$(( SIZE + 4 ))M

truncate -s "$IMG_SIZE" /work/rootfs.img
mke2fs -t ext2 -d "$ROOT" /work/rootfs.img

# Copy to output
mkdir -p /host/build/bin/qemu/linux-${ARCH}/rootfs
cp /work/rootfs.img /host/build/bin/qemu/linux-${ARCH}/rootfs/
