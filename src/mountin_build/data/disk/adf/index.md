---
format: disk/adf
requires:
  - docker:builder/disk/alpine
build_requires:
  - data/templates/basic.tar
provides:
  - data/disk/basic.ofs.adf
  - data/disk/basic.ffs.adf
---

# ADF Test Images

Genuine 80-track, double-density Amiga floppy images populated from the
standard test-data template. One uses OFS and the other FFS; both are exactly
901,120 bytes.
