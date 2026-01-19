---
title: NetBSD 10.0 Rootfs
requires:
  - bin/${ARCH}-netbsd/simple9p
  - bin/${ARCH}-netbsd/socat
provides:
  - bin/qemu/${ARCH}-netbsd/10.0/rootfs/ramdisk.fs
---

# NetBSD 10.0 Rootfs

Ramdisk image with rescue binaries, init scripts, and qemount tools.
