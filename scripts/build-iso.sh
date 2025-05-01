#!/bin/bash

# Script to run the QEMU microVM (rootless, no KVM)
ARCH=$1
KERNEL_VERSION=6.5

KERNEL_IMAGE=build/linux-${KERNEL_VERSION}/arch/${ARCH}/boot/bzImage
INITRD=build/initramfs/initramfs.cpio.gz
FS_ISO=build/fs/iso9660/rootfs.iso

echo "Starting QEMU in rootless mode..."

qemu-system-${ARCH} \
    -kernel $KERNEL_IMAGE \
    -initrd $INITRD \
    -append "console=ttyS0 root=/dev/ram0" \
    -cdrom $FS_ISO \
    -device virtio-net,netdev=usernet \
    -netdev user,id=usernet,hostfwd=tcp::2222-:22 \
    -nographic

echo "QEMU exited"
