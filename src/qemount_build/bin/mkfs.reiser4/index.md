---
title: mkfs.reiser4
build_requires:
  - sources/libaal-1.0.7.tar.gz
  - sources/reiser4progs-1.2.2.tar.gz
requires: []
provides:
  - bin/${HOST_ARCH}-linux-gnu/mkfs.reiser4
  - bin/${HOST_ARCH}-linux-gnu/reiser4-busy
---

# mkfs.reiser4

Static build of mkfs.reiser4 for creating Reiser4 filesystems.
Built on glibc (Debian) to avoid musl compatibility issues.
