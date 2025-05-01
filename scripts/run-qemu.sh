#!/bin/bash
set -eux

ARCH=${ARCH:-x86_64}
KERNEL_VERSION=${KERNEL_VERSION:-6.5}
KERNEL_IMAGE=${KERNEL_IMAGE:-build/linux/linux-${KERNEL_VERSION}/arch/${ARCH}/boot/bzImage}
INITRAMFS_IMAGE=${INITRAMFS_IMAGE:-build/initramfs/initramfs.cpio.gz}
ISO_IMAGE=${ISO_IMAGE:-build/fs/iso9660/rootfs.iso}

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
    -append "console=ttyS0 root=/dev/ram0" \
    -cdrom "$ISO_IMAGE" \
    -device virtio-net,netdev=usernet \
    -netdev user,id=usernet,hostfwd=tcp::2222-:22 \
    -nographic

echo "QEMU exited"
