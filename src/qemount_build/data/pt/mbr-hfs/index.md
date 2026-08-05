---
format: pt/mbr
requires:
  - docker:builder/disk/alpine
build_requires:
  - data/fs/basic.hfs
provides:
  - data/pt/hfs.mbr
---

# MBR HFS Test Image

An Apple HFS partition in a DOS/MBR partition table. This provides a compact
fixture for systems which support both the legacy PC partition scheme and the
classic Macintosh filesystem.
