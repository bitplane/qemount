---
title: mkfs.sysv
build_requires:
  - sources/mkfs-sysv-0.1.0.tar.gz
requires:
  - docker:builder/compiler/rust
provides:
  - bin/${TARGET_ARCH}-linux-musl/mkfs.sysv
---

# mkfs.sysv

Static musl build of [bitplane/mkfs-sysv](https://github.com/bitplane/mkfs-sysv)
(Rust). Creates SVR4 (System V) filesystem images.
