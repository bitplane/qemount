---
format: pt/gpt
requires:
  - docker:builder/disk/alpine
build_requires:
  - data/fs/basic.fat32
  - data/fs/basic.ext4
  - data/fs/basic.xfs
provides:
  - data/pt/hybrid.gpt
---

# Hybrid MBR/GPT Test Image

GPT disk with hybrid MBR - the MBR contains real partition entries
that mirror some GPT partitions. Used on some Macs for dual-boot.

Tests that both pt/gpt and pt/mbr correctly enumerate partitions
when both tables contain valid data.
