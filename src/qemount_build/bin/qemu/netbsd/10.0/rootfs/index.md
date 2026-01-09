---
title: NetBSD 10.0 Rootfs
requires:
  - bin/netbsd-${ARCH}/simple9p/simple9p
  - bin/netbsd-${ARCH}/socat/socat
provides:
  - bin/qemu/netbsd-${ARCH}/10.0/rootfs/ramdisk.fs
---

# NetBSD 10.0 Rootfs

Ramdisk image with rescue binaries, init scripts, and qemount tools.
