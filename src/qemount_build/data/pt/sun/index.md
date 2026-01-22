---
format: pt/sun
requires:
  - docker:builder/disk/debian
build_requires:
  - data/fs/basic.ufs1
  - data/fs/basic.ufs2
provides:
  - data/pt/basic.sun
---

# Sun VTOC Test Image

Sun disk label with 2 partitions: UFS1 and UFS2.
