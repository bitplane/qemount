---
title: Linux Rootfs
env:
  BUILDER: builder/compiler/linux/6:${HOST_ARCH}
requires:
  - docker:${BUILDER}
  - bin/${ARCH}-linux-${ENV}/busybox
  - bin/${ARCH}-linux-${ENV}/simple9p
  - bin/${ARCH}-linux-${ENV}/socat
  - bin/${ARCH}-linux-${ENV}/dropbearmulti
provides:
  - bin/qemu/${ARCH}-linux/rootfs/rootfs.img
---

# Linux Rootfs

Shared rootfs image for Linux QEMU guests. Contains busybox, simple9p, socat,
and dropbear - all statically linked so works with any kernel version.
