---
format: pt/mbr
requires:
  - docker:builder/disk/alpine
build_requires:
  - data/fs/basic.fat12
  - data/fs/basic.fat16
  - data/fs/basic.fat32
provides:
  - data/pt/basic.mbr
---

# MBR Simple Test Image

MBR disk with three primary partitions containing FAT12, FAT16, and FAT32
filesystems.
