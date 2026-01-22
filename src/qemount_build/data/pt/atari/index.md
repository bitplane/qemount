---
format: pt/atari
build_requires:
  - data/fs/basic.fat16
  - data/fs/basic.fat12
provides:
  - data/pt/basic.atari
---

# Atari AHDI Test Image

Atari AHDI partition table with two partitions:
- Partition 0: BGM (16MB FAT16)
- Partition 1: GEM (8MB FAT12)
