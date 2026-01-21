---
format: pt/amiga-rdb
requires:
  - docker:builder/disk/alpine
build_requires:
  - data/fs/basic.amiga-ffs
  - data/fs/basic.amiga-ofs
provides:
  - data/pt/basic.amiga-rdb
---

# Amiga RDB Test Image

RDB disk with 2 partitions containing FFS and OFS filesystems.
