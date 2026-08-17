---
title: NetBSD 10.0 base rootfs
requires:
  - bin/${OUTPUT_ARCH}-netbsd/mountin-rescue
  - share/${OUTPUT_ARCH}-netbsd/mountin-devices.mtree
provides:
  - docker:builder/guest/netbsd/10.0/rootfs/${OUTPUT_ARCH}
  - guest/${OUTPUT_ARCH}-netbsd/10.0/rootfs/ramdisk.fs
---

# NetBSD 10.0 Rootfs

Fixed-size ramdisk containing the shell and fixture command set. The appliance
rootfs is produced separately by adding 9d.
