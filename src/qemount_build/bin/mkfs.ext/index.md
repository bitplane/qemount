---
title: mkfs.ext
requires:
  - docker:builder/compiler/linux/6
provides:
  - bin/${HOST_ARCH}-linux-musl/mkfs.ext
---

# mkfs.ext

Minimal original ext filesystem creator. Creates empty ext filesystem images
for testing. Based on Linux 1.0 kernel ext_fs.h structures and Remy Card's
original efsprogs (1992-1993).
