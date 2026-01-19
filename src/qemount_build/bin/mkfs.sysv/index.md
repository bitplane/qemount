---
title: mkfs.sysv
requires:
  - docker:builder/compiler/linux/6:${HOST_ARCH}
provides:
  - bin/${HOST_ARCH}-linux-musl/mkfs.sysv
---

# mkfs.sysv

Minimal SVR4 filesystem creator. Creates empty SystemV filesystem images
for testing. Based on Linux kernel sysv_fs.h structures.
