---
title: NetBSD Disk Builder
build_platforms:
  x86_64-linux: {}
  aarch64-linux: {}
env:
  BUILDER: builder/compiler/netbsd/10.0/${BUILD_ARCH}
requires:
  - docker:${BUILDER}
provides:
  - docker:builder/disk/netbsd
---

# NetBSD Disk Builder

Debian-based image with NetBSD's makefs for creating disk images.
Supports v7fs, ffs (UFS), cd9660, and msdos filesystems.
