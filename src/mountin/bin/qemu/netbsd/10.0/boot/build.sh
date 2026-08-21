#!/bin/sh
set -e

NBARCH=$(cat /tmp/nbarch)
NBGNUTRIPLE=$(cat /tmp/nbgnutriple)
DESTDIR="/usr/obj/destdir.$NBARCH"
TOOLDIR="/usr/tools"
KERNEL_DIR="/host/build/guest/${MOUNTIN_TARGET_ARCH}-netbsd/10.0/kernel"
ROOTFS_DIR="/host/build/guest/${MOUNTIN_TARGET_ARCH}-netbsd/10.0/appliance/rootfs"
OUTPUT_DIR="/host/build/bin/qemu/${MOUNTIN_TARGET_ARCH}-netbsd/10.0/boot"

echo "Assembling NetBSD boot image for $MOUNTIN_TARGET_ARCH..."

# Copy kernel and ramdisk from build
cp "$KERNEL_DIR/netbsd.gdb" /work/netbsd.gdb
cp "$ROOTFS_DIR/ramdisk.fs" /work/ramdisk.fs

# Embed ramdisk into kernel
echo "Embedding ramdisk into kernel..."
"$TOOLDIR/bin/${NBGNUTRIPLE}--netbsd-mdsetimage" \
    -v /work/netbsd.gdb /work/ramdisk.fs

# Strip the kernel
echo "Stripping kernel..."
"$TOOLDIR/bin/${NBGNUTRIPLE}--netbsd-strip" \
    -o /work/netbsd.stripped /work/netbsd.gdb

case "$MOUNTIN_TARGET_ARCH" in
    x86_64)
        mkdir -p "$OUTPUT_DIR"
        cp /work/netbsd.stripped "$OUTPUT_DIR/netbsd"

        echo "Creating BIOS boot image..."
        mkdir -p /work/bootfs
        cp /work/netbsd.stripped /work/bootfs/netbsd
        cp "$DESTDIR/usr/mdec/boot" /work/bootfs/boot
        cp /boot.cfg /work/bootfs/boot.cfg

        "$TOOLDIR/bin/nbmakefs" -t ffs -o version=1 \
            /work/boot.img /work/bootfs
        sectors=$(( $(stat -c %s /work/boot.img) / 512 ))
        cylinders=$(( (sectors + 2047) / 2048 ))
        sed -e "s/@CYLINDERS@/$cylinders/" \
            -e "s/@SECTORS@/$sectors/g" /disklabel.template \
            > /work/disklabel.proto
        "$TOOLDIR/bin/nbdisklabel" -M "$NBARCH" -R -F \
            /work/boot.img /work/disklabel.proto
        "$TOOLDIR/bin/nbinstallboot" -m "$NBARCH" -o timeout=0 \
            /work/boot.img "$DESTDIR/usr/mdec/bootxx_ffsv1"
        cp /work/boot.img "$OUTPUT_DIR/boot.img"
        ;;
    aarch64)
        # Match NetBSD's evbarm64 mk.generic64 rules. QEMU cannot boot the
        # regular high-address ELF kernel directly.
        mkdir -p "$OUTPUT_DIR"
        "$TOOLDIR/bin/${NBGNUTRIPLE}--netbsd-objcopy" \
            -S -O binary /work/netbsd.stripped /work/netbsd.bin
        "$TOOLDIR/bin/nbmkubootimage" -f arm64 -u -a 0x200000 \
            /work/netbsd.bin "$OUTPUT_DIR/netbsd"
        ;;
    *)
        echo "Unsupported NetBSD boot architecture: $MOUNTIN_TARGET_ARCH" >&2
        exit 1
        ;;
esac

echo "Done! Kernel: netbsd"
