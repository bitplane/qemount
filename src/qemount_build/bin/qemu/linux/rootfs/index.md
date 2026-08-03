---
title: Linux Rootfs
env:
  BUILDER: builder/compiler/linux/6
requires:
  - docker:${BUILDER}
  - bin/${OUTPUT_ARCH}-linux-${ENV}/busybox
  - bin/${OUTPUT_ARCH}-linux-${ENV}/simple9p
  - bin/${OUTPUT_ARCH}-linux-${ENV}/socat
  - bin/${OUTPUT_ARCH}-linux-${ENV}/dropbearmulti
provides:
  - bin/qemu/${OUTPUT_ARCH}-linux/rootfs/rootfs.img
---

# Linux Rootfs

Shared rootfs image for Linux QEMU guests. Contains busybox, simple9p, socat,
and dropbear - all statically linked so works with any kernel version.
