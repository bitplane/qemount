---
format: pt/plan9
requires:
  - docker:builder/disk/9front
build_requires:
  - bin/qemu/x86_64-9front/11957/9front.iso
  - data/templates/basic.tar
provides:
  - data/pt/basic.plan9
---

# Plan 9 Partition Table Test Image

DOS-partitioned disk containing a type `0x39` Plan 9 partition. Its native
text partition table contains an HJFS `fs` partition populated from the
standard test-data template. The builder creates and traverses every layer
with 9front before returning the image.
