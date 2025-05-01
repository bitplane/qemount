#!/bin/bash

# Script to run the QEMU microVM (rootless, no KVM)
ARCH=$1
KERNEL_VERSION=6.5

KERNEL_IMAGE=build/linux/linux-${KERNEL_VERSION}/arch/${ARCH}/boot/bzImage
INITRD=build/initramfs/initramfs.cpio.gz
FS_ISO=build/fs/iso9660/rootfs.iso

if [ ! -f "$KERNEL_IMAGE" ]; then
  echo "Error: kernel image not found: $KERNEL_IMAGE" >&2
  exit 1
fi
if [ ! -f "$INITRD" ]; then
  echo "Error: initramfs not found: $INITRD" >&2
  exit 1
fi
if [ ! -f "$FS_ISO" ]; then
  echo "Error: ISO image not found: $FS_ISO" >&2
  exit 1
fi

echo "Starting QEMU in rootless mode..."

qemu-system-${ARCH} \
    -kernel "$KERNEL_IMAGE" \
    -initrd "$INITRD" \
    -append "console=ttyS0 root=/dev/ram0" \
    -cdrom "$FS_ISO" \
    -device virtio-net,netdev=usernet \
    -netdev user,id=usernet,hostfwd=tcp::2222-:22 \
    -nographic

echo "QEMU exited"
