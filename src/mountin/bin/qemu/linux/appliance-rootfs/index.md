---
title: Linux appliance rootfs
env:
  BUILDER: builder/compiler/linux/6
requires:
  - docker:${BUILDER}
  - guest/${OUTPUT_ARCH}-linux/base/rootfs.img
  - bin/${OUTPUT_ARCH}-linux-${ENV}/9d
provides:
  - bin/qemu/${OUTPUT_ARCH}-linux/rootfs/rootfs.img
---

# Linux appliance rootfs

Adds 9d to the reusable Linux base rootfs.
