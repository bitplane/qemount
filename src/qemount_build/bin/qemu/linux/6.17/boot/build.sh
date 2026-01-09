#!/bin/sh
set -e

mkdir -p /host/build/bin/qemu/linux-${ARCH}/6.17/boot

cp -v /host/build/bin/qemu/linux-${ARCH}/6.17/kernel \
      /host/build/bin/qemu/linux-${ARCH}/6.17/boot/kernel

cp -v /host/build/bin/qemu/linux-${ARCH}/rootfs/rootfs.img \
      /host/build/bin/qemu/linux-${ARCH}/6.17/boot/rootfs.img

echo "Done! Boot files ready."
