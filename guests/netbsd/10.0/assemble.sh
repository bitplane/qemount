#!/bin/sh
# Assemble NetBSD boot image from kernel + ramdisk
set -eu

OUTPUT_PATH="$1"
ARCH="${ARCH:-x86_64}"

NBARCH=$(cat /tmp/nbarch)
NBKERNARCH=$(cat /tmp/nbkernarch)
NBGNUTRIPLE=$(cat /tmp/nbgnutriple)
DESTDIR="/usr/obj/destdir.$NBARCH"
TOOLDIR="/usr/tools"

echo "Assembling NetBSD boot image for $ARCH..."

# Copy kernel and ramdisk from host build
cp /host/build/guests/netbsd/10.0/${ARCH}/netbsd.gdb /build/netbsd.gdb
cp /host/build/guests/netbsd/ramdisk/${ARCH}/ramdisk.fs /build/ramdisk.fs

# Embed ramdisk into kernel using mdsetimage
echo "Embedding ramdisk into kernel..."
/usr/obj/tools/mdsetimage/mdsetimage -v /build/netbsd.gdb /build/ramdisk.fs

# Strip the kernel (reduces ~180MB to ~20MB)
echo "Stripping kernel..."
$TOOLDIR/bin/${NBGNUTRIPLE}--netbsd-strip -o /build/netbsd.stripped /build/netbsd.gdb

# Create bootable disk image
echo "Creating boot image..."
mkdir -p /build/bootfs
cp /build/netbsd.stripped /build/bootfs/netbsd
cp $DESTDIR/usr/mdec/boot /build/bootfs/boot
cp /build/boot.cfg /build/bootfs/boot.cfg

$TOOLDIR/bin/nbmakefs -s 48m -t ffs -o version=1 /build/boot.img /build/bootfs
$TOOLDIR/bin/nbdisklabel -M $NBARCH -R -F /build/boot.img /build/disklabel.proto
$TOOLDIR/bin/nbinstallboot -m $NBARCH -o timeout=0 /build/boot.img $DESTDIR/usr/mdec/bootxx_ffsv1

# Copy outputs
mkdir -p /outputs/guests/netbsd/10.0/${ARCH}
cp /build/boot.img /outputs/guests/netbsd/10.0/${ARCH}/boot.img
cp /build/netbsd.stripped /outputs/guests/netbsd/10.0/${ARCH}/netbsd

echo "Done! Boot image: /outputs/guests/netbsd/10.0/${ARCH}/boot.img"

# Deploy using standard script
/usr/local/bin/deploy.sh guests/netbsd/10.0/${ARCH}/boot.img
/usr/local/bin/deploy.sh guests/netbsd/10.0/${ARCH}/netbsd
