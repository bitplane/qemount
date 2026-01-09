---
title: Linux Rootfs
env:
  BUILDER: builder/compiler/linux/6:${HOST_ARCH}
requires:
  - docker:${BUILDER}
  - bin/linux-${ARCH}/busybox/busybox
  - bin/linux-${ARCH}/simple9p/simple9p
  - bin/linux-${ARCH}/socat/socat
  - bin/linux-${ARCH}/dropbear/dropbearmulti
provides:
  - bin/qemu/linux-${ARCH}/rootfs/rootfs.img
---

# Linux Rootfs

Shared rootfs image for Linux QEMU guests. Contains busybox, simple9p, socat,
and dropbear - all statically linked so works with any kernel version.
