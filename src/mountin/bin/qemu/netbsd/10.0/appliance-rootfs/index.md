---
title: NetBSD 10.0 appliance rootfs
runs_on: docker:builder/guest/netbsd/10.0/rootfs/${TARGET_ARCH}
requires:
  - docker:builder/guest/netbsd/10.0/rootfs/${TARGET_ARCH}
  - bin/${TARGET_ARCH}-netbsd/9d
provides:
  - guest/${TARGET_ARCH}-netbsd/10.0/appliance/rootfs/ramdisk.fs
---

# NetBSD 10.0 appliance rootfs

Adds 9d to the reusable fixed-size NetBSD ramdisk.
