---
title: mkfs.mfs
requires:
  - docker:builder/compiler/linux/6
provides:
  - bin/${HOST_ARCH}-linux-musl/mkfs.mfs
---

# mkfs.mfs

Minimal Macintosh File System (MFS) image creator. Creates MFS filesystem
images for testing, based on Apple's "Inside Macintosh, Volume II" (1985).
MFS was the original Macintosh filesystem from 1984.
