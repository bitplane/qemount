---
title: NetBSD 10.0 Kernel
requires:
  - sources/netbsd-10.0-syssrc.tgz
  - bin/qemu/${OUTPUT_ARCH}-netbsd/10.0/rootfs/ramdisk.sectors
provides:
  - bin/qemu/${OUTPUT_ARCH}-netbsd/10.0/kernel/netbsd.gdb
---

# NetBSD 10.0 Kernel

Kernel build with the MOUNTIN config. The source and object tree are retained in
the provider cache; they are not carried by the compiler image.
