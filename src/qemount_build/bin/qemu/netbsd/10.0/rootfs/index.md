---
title: NetBSD 10.0 Rootfs
requires:
  - bin/${OUTPUT_ARCH}-netbsd/simple9p
  - bin/${OUTPUT_ARCH}-netbsd/socat
provides:
  - bin/qemu/${OUTPUT_ARCH}-netbsd/10.0/rootfs/ramdisk.fs
---

# NetBSD 10.0 Rootfs

Ramdisk image with rescue binaries, init scripts, and qemount tools.
