---
title: mkfs.ext
build_requires:
  - sources/mkfs-ext-0.1.0.tar.gz
requires:
  - docker:builder/compiler/rust
provides:
  - bin/${MOUNTIN_TARGET_ARCH}-linux-musl/mkfs.ext
---

# mkfs.ext

Static musl build of [bitplane/mkfs-ext](https://github.com/bitplane/mkfs-ext)
(Rust). Creates original ext (pre-ext2) filesystem images.
