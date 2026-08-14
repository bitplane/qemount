---
format: pt/mbr
requires:
  - docker:builder/disk/alpine
build_requires:
  - data/fs/basic.ufs-solaris
provides:
  - data/pt/basic.solaris-x86-vtoc
---

# Solaris x86 VTOC16 Test Image

MBR disk with a Solaris2 partition containing a little-endian VTOC16 label and
a Solaris UFS slice.

