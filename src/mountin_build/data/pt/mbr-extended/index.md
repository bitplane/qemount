---
format: pt/mbr
requires:
  - docker:builder/disk/alpine
build_requires:
  - data/fs/basic.fat16
  - data/fs/basic.fat32
  - data/fs/basic.ext2
  - data/fs/basic.ext3
  - data/fs/basic.ext4
  - data/fs/basic.xfs
provides:
  - data/pt/extended.mbr
---

# MBR Extended Partition Test Image

MBR disk with 1 primary partition and an extended partition containing 5 logical partitions.
Tests EBR chain parsing with multiple logicals.
