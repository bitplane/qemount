---
title: Linux base rootfs
env:
  BUILDER: builder/compiler/linux/6
requires:
  - docker:${BUILDER}
  - bin/${OUTPUT_ARCH}-linux-${ENV}/busybox
  - bin/${OUTPUT_ARCH}-linux-${ENV}/socat
  - bin/${OUTPUT_ARCH}-linux-${ENV}/dropbearmulti
provides:
  - guest/${OUTPUT_ARCH}-linux/base/rootfs.img
---

# Linux Rootfs

Reusable shell and fixture rootfs. The appliance-specific stage adds 9d.
