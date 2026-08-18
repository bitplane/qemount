---
title: mkfs.reiserfs
build_platforms:
  x86_64-linux: {}
  aarch64-linux: {}
output_platforms:
  x86_64-linux-gnu:
    build_platforms:
      x86_64-linux: {}
  aarch64-linux-gnu:
    build_platforms:
      aarch64-linux: {}
build_requires:
  - sources/reiserfsprogs-3.6.27.tar.xz
requires: []
provides:
  - bin/${TARGET_ARCH}-linux-gnu/mkfs.reiserfs
---

# reiserfsprogs

Static build of mkfs.reiserfs for creating ReiserFS filesystems.
Built on glibc to avoid musl compatibility issues.
