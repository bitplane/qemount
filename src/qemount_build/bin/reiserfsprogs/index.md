---
title: reiserfsprogs
build_requires:
  - sources/reiserfsprogs-3.6.27.tar.xz
requires: []
provides:
  - bin/${HOST_ARCH}-linux-gnu/mkfs.reiserfs
---

# reiserfsprogs

Static build of mkfs.reiserfs for creating ReiserFS filesystems.
Built on glibc to avoid musl compatibility issues.
