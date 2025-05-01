#!/bin/bash
set -eux

ARCH=$1
KERNEL_IMAGE=$2
INITRAMFS_IMAGE=$3
ISO_IMAGE=$4

if [ ! -f "$KERNEL_IMAGE" ]; then
  echo "Error: kernel image not found: $KERNEL_IMAGE" >&2
  exit 1
fi
if [ ! -f "$INITRAMFS_IMAGE" ]; then
  echo "Error: initramfs not found: $INITRAMFS_IMAGE" >&2
  exit 1
fi
if [ ! -f "$ISO_IMAGE" ]; then
  echo "Error: ISO image not found: $ISO_IMAGE" >&2
  exit 1
fi

echo "Starting QEMU in rootless mode..."

qemu-system-${ARCH} \
    -kernel "$KERNEL_IMAGE" \
    -initrd "$INITRAMFS_IMAGE" \
    -append "console=ttyS0 earlyprintk=serial,ttyS0 root=/dev/ram0 init=/init"
    -cdrom "$ISO_IMAGE" \
    -device virtio-net,netdev=usernet \
    -netdev user,id=usernet,hostfwd=tcp::2222-:22 \
    -nographic

echo "QEMU exited"
