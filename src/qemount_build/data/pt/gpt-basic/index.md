---
format: pt/gpt
requires:
  - docker:builder/disk/alpine
build_requires:
  - data/fs/basic.fat32
  - data/fs/basic.ext2
  - data/fs/basic.ext3
  - data/fs/basic.ext4
  - data/fs/basic.xfs
  - data/fs/basic.btrfs
provides:
  - data/pt/basic.gpt
---

# GPT Test Image

GPT disk with 6 partitions using various filesystem types.
Tests flat partition entry parsing.
