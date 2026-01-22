---
format: pt/bsd-disklabel
requires:
  - docker:builder/disk/netbsd
build_requires:
  - data/fs/basic.ufs1
  - data/fs/basic.ufs2
provides:
  - data/pt/basic.bsd-disklabel
---

# BSD Disklabel Test Image

Disklabel with 2 partitions: UFS1 (partition a) and UFS2 (partition e).
