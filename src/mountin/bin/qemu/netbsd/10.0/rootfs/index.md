---
title: NetBSD 10.0 Rootfs
requires:
  - bin/${OUTPUT_ARCH}-netbsd/9d
  - bin/${OUTPUT_ARCH}-netbsd/mountin-rescue
  - share/${OUTPUT_ARCH}-netbsd/mountin-devices.mtree
provides:
  - bin/qemu/${OUTPUT_ARCH}-netbsd/10.0/rootfs/ramdisk.fs
  - bin/qemu/${OUTPUT_ARCH}-netbsd/10.0/rootfs/ramdisk.sectors
---

# NetBSD 10.0 Rootfs

Automatically sized ramdisk containing the mountin command set, static device
nodes, init scripts, and 9P server.
