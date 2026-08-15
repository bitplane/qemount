---
format: pt/atari
build_requires:
  - data/fs/basic.gemdos
  - data/fs/basic.fat16
  - data/fs/basic.fat12
provides:
  - data/pt/basic.atari
---

# Atari AHDI Test Image

Atari AHDI partition table with three partitions:
- Partition 0: GEM (720KB GEMDOS boot partition with Atari boot checksum)
- Partition 1: BGM (16MB FAT16 data partition)
- Partition 2: GEM (8MB FAT12 data partition)
