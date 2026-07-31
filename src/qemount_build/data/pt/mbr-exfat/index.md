---
format: pt/mbr
requires:
  - docker:builder/disk/alpine
build_requires:
  - data/fs/basic.exfat
provides:
  - data/pt/exfat.mbr
---

# MBR exFAT Test Image

MBR disk with one Microsoft basic-data partition containing the canonical
exFAT filesystem fixture. This complements the raw exFAT superfloppy image.
