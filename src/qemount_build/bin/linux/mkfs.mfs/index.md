---
title: mkfs.mfs
build_requires:
  - sources/mkfs-mfs-0.1.0.tar.gz
requires:
  - docker:builder/compiler/rust
provides:
  - bin/${OUTPUT_ARCH}-linux-musl/mkfs.mfs
---

# mkfs.mfs

Static musl build of [bitplane/mkfs-mfs](https://github.com/bitplane/mkfs-mfs)
(Rust). Creates Macintosh File System (MFS) disk images.
