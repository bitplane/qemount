#!/bin/sh
set -e

mkdir -p /host/build/bin/qemu/${ARCH}-linux/6.12/boot

cp -v /host/build/bin/qemu/${ARCH}-linux/6.12/kernel \
      /host/build/bin/qemu/${ARCH}-linux/6.12/boot/kernel

cp -v /host/build/bin/qemu/${ARCH}-linux/rootfs/rootfs.img \
      /host/build/bin/qemu/${ARCH}-linux/6.12/boot/rootfs.img

echo "Done! Boot files ready."
