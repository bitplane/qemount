---
title: NetBSD Disk Builder
requires:
  - docker:builder/compiler/netbsd/10.0:${HOST_ARCH}
provides:
  - docker:builder/disk/netbsd
---

# NetBSD Disk Builder

Debian-based image with NetBSD's makefs for creating disk images.
Supports v7fs, ffs (UFS), cd9660, and msdos filesystems.
