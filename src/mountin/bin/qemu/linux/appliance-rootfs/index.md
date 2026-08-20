---
title: Linux appliance rootfs
requires:
  - docker:${MOUNTIN_BUILDER}
  - guest/${MOUNTIN_TARGET_ARCH}-linux/base/rootfs.img
  - bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/9d
provides:
  - bin/qemu/${MOUNTIN_TARGET_ARCH}-linux/rootfs/rootfs.img
---

# Linux appliance rootfs

Adds 9d to the reusable Linux base rootfs.
