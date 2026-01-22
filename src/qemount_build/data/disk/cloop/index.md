---
format: disk/cloop
requires:
  - docker:builder/disk/debian
build_requires:
  - data/fs/basic.iso9660
provides:
  - data/disk/basic.cloop
---

# cloop Test Image

Compressed loopback disk image containing ISO9660 filesystem.
