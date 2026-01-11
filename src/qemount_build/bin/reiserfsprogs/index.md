---
title: reiserfsprogs
build_requires:
  - sources/reiserfsprogs-3.6.27.tar.xz
requires: []
provides:
  - bin/linux-${HOST_ARCH}/reiserfsprogs/mkfs.reiserfs
---

# reiserfsprogs

Static build of mkfs.reiserfs for creating ReiserFS filesystems.
Built on glibc to avoid musl compatibility issues.
