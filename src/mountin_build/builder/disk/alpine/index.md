---
title: Alpine Disk Builder
build_requires:
  - sources/cramfs-tools-2.1.tar.gz
provides:
  - docker:builder/disk/alpine
---

# Alpine Disk Builder

Alpine-based image with filesystem tools for creating disk images that
don't require mount access. Includes mkfs utilities for ext2/3/4, FAT,
squashfs, erofs, and archive tools.
