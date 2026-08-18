---
title: mkfs.xiafs
build_requires:
  - sources/mkfs-xiafs-0.1.0.tar.gz
requires:
  - docker:builder/compiler/rust
provides:
  - bin/${MOUNTIN_TARGET_ARCH}-linux-musl/mkfs.xiafs
---

# mkfs.xiafs

Static musl build of [bitplane/mkfs-xiafs](https://github.com/bitplane/mkfs-xiafs)
(Rust). Creates xiafs filesystem images.
