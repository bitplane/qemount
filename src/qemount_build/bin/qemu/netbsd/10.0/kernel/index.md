---
title: NetBSD 10.0 Kernel
provides:
  - bin/qemu/${OUTPUT_ARCH}-netbsd/10.0/kernel/netbsd.gdb
---

# NetBSD 10.0 Kernel

Kernel build with QEMOUNT config. Unstripped for mdsetimage to embed ramdisk.
The kernel object tree is retained in the build cache for incremental rebuilds.
