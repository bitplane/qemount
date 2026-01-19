#!/bin/sh
set -e

NBARCH=$(cat /tmp/nbarch)
NBKERNARCH=$(cat /tmp/nbkernarch)
NBGNUTRIPLE=$(cat /tmp/nbgnutriple)
DESTDIR="/usr/obj/destdir.$NBARCH"
TOOLDIR="/usr/tools"

echo "Assembling NetBSD boot image for $ARCH..."

# Copy kernel and ramdisk from build
cp /host/build/bin/qemu/${ARCH}-netbsd/10.0/kernel/netbsd.gdb /work/netbsd.gdb
cp /host/build/bin/qemu/${ARCH}-netbsd/10.0/rootfs/ramdisk.fs /work/ramdisk.fs

# Embed ramdisk into kernel
echo "Embedding ramdisk into kernel..."
/usr/obj/tools/mdsetimage/mdsetimage -v /work/netbsd.gdb /work/ramdisk.fs

# Strip the kernel
echo "Stripping kernel..."
$TOOLDIR/bin/${NBGNUTRIPLE}--netbsd-strip -o /work/netbsd.stripped /work/netbsd.gdb

# Create bootable disk image
echo "Creating boot image..."
mkdir -p /work/bootfs
cp /work/netbsd.stripped /work/bootfs/netbsd
cp $DESTDIR/usr/mdec/boot /work/bootfs/boot
cp /boot.cfg /work/bootfs/boot.cfg

$TOOLDIR/bin/nbmakefs -s 48m -t ffs -o version=1 /work/boot.img /work/bootfs
$TOOLDIR/bin/nbdisklabel -M $NBARCH -R -F /work/boot.img /disklabel.proto
$TOOLDIR/bin/nbinstallboot -m $NBARCH -o timeout=0 /work/boot.img $DESTDIR/usr/mdec/bootxx_ffsv1

# Copy to output
mkdir -p /host/build/bin/qemu/${ARCH}-netbsd/10.0/boot
cp /work/boot.img /host/build/bin/qemu/${ARCH}-netbsd/10.0/boot/boot.img
cp /work/netbsd.stripped /host/build/bin/qemu/${ARCH}-netbsd/10.0/boot/netbsd

echo "Done! Boot image: boot.img"
