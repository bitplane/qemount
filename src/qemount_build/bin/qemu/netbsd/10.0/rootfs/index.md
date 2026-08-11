---
title: NetBSD 10.0 Rootfs
requires:
  - bin/${OUTPUT_ARCH}-netbsd/simple9p
  - bin/${OUTPUT_ARCH}-netbsd/qemount-rescue
  - share/${OUTPUT_ARCH}-netbsd/qemount-devices.mtree
provides:
  - bin/qemu/${OUTPUT_ARCH}-netbsd/10.0/rootfs/ramdisk.fs
  - bin/qemu/${OUTPUT_ARCH}-netbsd/10.0/rootfs/ramdisk.sectors
---

# NetBSD 10.0 Rootfs

Automatically sized ramdisk containing the qemount command set, static device
nodes, init scripts, and 9P server.
