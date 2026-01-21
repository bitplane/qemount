---
format: pt/mbr
requires:
  - docker:builder/disk/alpine
build_requires:
  - data/fs/basic.fat16
  - data/fs/basic.fat32
provides:
  - data/pt/basic.mbr
---

# MBR Simple Test Image

MBR disk with 2 primary partitions containing FAT16 and FAT32 filesystems.
