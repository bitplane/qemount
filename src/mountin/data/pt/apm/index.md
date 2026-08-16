---
format: pt/apm
requires:
  - docker:builder/disk/debian
build_requires:
  - data/fs/basic.hfs
  - data/fs/basic.hfsplus
  - data/fs/basic.prodos
provides:
  - data/pt/basic.apm
---

# APM Test Image

Apple Partition Map with 3 partitions: HFS, HFS+, and ProDOS. The ProDOS
partition proves the Apple hard-disk path `disk -> pt/apm -> fs/prodos`: the
`pt/apm` driver slices out each partition and the recursion engine detects the
ProDOS volume inside the third one (typed `Apple_PRODOS`).
