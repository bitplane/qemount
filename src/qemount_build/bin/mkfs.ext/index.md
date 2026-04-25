---
title: mkfs.ext
env:
  CARGO_HOME: /host/build/cache/cargo
  CARGO_TARGET_DIR: /host/build/cache/cargo-target
  ZIG_GLOBAL_CACHE_DIR: /host/build/cache/zig
build_requires:
  - sources/mkfs-ext-0.1.0.tar.gz
requires:
  - docker:builder/compiler/rust
provides:
  - bin/${HOST_ARCH}-linux-musl/mkfs.ext
---

# mkfs.ext

Static musl build of [bitplane/mkfs-ext](https://github.com/bitplane/mkfs-ext)
(Rust). Creates original ext (pre-ext2) filesystem images.
