---
format: pt/sun-sparc
requires:
  - docker:builder/disk/debian
build_requires:
  - data/fs/basic.ufs1
  - data/fs/basic.ufs2
provides:
  - data/pt/basic.sun-sparc
---

# Sun SPARC Disklabel Test Image

Big-endian Sun SPARC VTOC8 disk label with two partitions: UFS1 and UFS2.
