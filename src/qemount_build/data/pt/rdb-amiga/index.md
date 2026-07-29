---
format: pt/rdb
requires:
  - docker:builder/disk/alpine
build_requires:
  - data/fs/basic.amiga-ofs
  - data/fs/basic.amiga-ffs
  - data/fs/basic.amiga-pfs
  - data/fs/basic.amiga-sfs
provides:
  - data/pt/amiga-filesystems.rdb
---

# Amiga Filesystems RDB Test Image

RDB disk containing four partitions populated from the standard test-data
template: OFS, FFS, PFS, and SFS.
