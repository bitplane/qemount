---
title: mkfs.tux3
requires:
  - docker:builder/compiler/linux/6
provides:
  - bin/${HOST_ARCH}-linux-musl/mkfs.tux3
---

# mkfs.tux3

Minimal Tux3 filesystem image creator. Creates images with a valid Tux3
superblock for detection testing. Based on Daniel Phillips' tux3 source.
