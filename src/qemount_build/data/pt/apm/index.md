---
format: pt/apm
requires:
  - docker:builder/disk/debian
build_requires:
  - data/fs/basic.hfs
  - data/fs/basic.hfsplus
provides:
  - data/pt/basic.apm
---

# APM Test Image

Apple Partition Map with 2 partitions: HFS and HFS+.
