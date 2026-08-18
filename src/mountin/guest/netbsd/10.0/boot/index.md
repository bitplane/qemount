---
title: NetBSD 10.0 fixture boot image
requires:
  - guest/${MOUNTIN_TARGET_ARCH}-netbsd/10.0/kernel/netbsd.gdb
  - guest/${MOUNTIN_TARGET_ARCH}-netbsd/10.0/rootfs/ramdisk.fs
output_platforms:
  x86_64-netbsd:
    provides:
      - guest/${MOUNTIN_TARGET_ARCH}-netbsd/10.0/boot/boot.img
      - guest/${MOUNTIN_TARGET_ARCH}-netbsd/10.0/boot/netbsd
  aarch64-netbsd:
    provides:
      - guest/${MOUNTIN_TARGET_ARCH}-netbsd/10.0/boot/netbsd
---

# NetBSD 10.0 fixture boot image

Embeds the reusable shell and fixture ramdisk in the source-built kernel.
