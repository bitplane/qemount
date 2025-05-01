#!/bin/bash

# Placeholder script to run the QEMU microVM (rootless, no KVM)
ARCH=$1

KERNEL_IMAGE=build/linux/arch/x86/boot/bzImage
INITRD=build/initramfs/initramfs.cpio.gz
# Example ISO filesystem (assuming it is built or placed at this path)
FS_ISO=build/fs/iso9660/rootfs.iso

echo "Starting QEMU in rootless mode..."

# Basic QEMU command line for x86_64 with ISO9660 filesystem
# Using user-mode networking and virtio devices
qemu-system-x86_64 \
    -kernel $KERNEL_IMAGE \
    -initrd $INITRD \
    -append "console=ttyS0 root=/dev/ram0" \
    -cdrom $FS_ISO \
    -device virtio-net,netdev=usernet \
    -netdev user,id=usernet,hostfwd=tcp::2222-:22 \
    -nographic

echo "QEMU exited"
