#!/bin/sh
set -e

mkdir -p /host/build/bin/qemu/${ARCH}-linux/2.6/boot

cp -v /host/build/bin/qemu/${ARCH}-linux/2.6/kernel \
      /host/build/bin/qemu/${ARCH}-linux/2.6/boot/kernel

cp -v /host/build/bin/qemu/${ARCH}-linux/rootfs/rootfs.img \
      /host/build/bin/qemu/${ARCH}-linux/2.6/boot/rootfs.img

echo "Done! Boot files ready."
