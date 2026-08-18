---
title: Linux base rootfs
env:
  MOUNTIN_BUILDER: builder/compiler/linux/6
requires:
  - docker:${MOUNTIN_BUILDER}
  - bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/busybox
  - bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/socat
  - bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/dropbearmulti
provides:
  - guest/${MOUNTIN_TARGET_ARCH}-linux/base/rootfs.img
---

# Linux Rootfs

Reusable shell and fixture rootfs. The appliance-specific stage adds 9d.
