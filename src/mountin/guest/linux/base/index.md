---
title: Linux base rootfs
requires:
  - docker:${MOUNTIN_BUILDER}
  - bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/busybox
  - share/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/busybox.links
  - bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/socat
  - bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/dropbearmulti
provides:
  - guest/${MOUNTIN_TARGET_ARCH}-linux/base/rootfs.img
---

# Linux Rootfs

Reusable shell and fixture rootfs. The appliance-specific stage adds 9d.
