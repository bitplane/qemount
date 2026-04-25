---
title: mkfs.xiafs
env:
  CARGO_HOME: /host/build/cache/cargo
  CARGO_TARGET_DIR: /host/build/cache/cargo-target
  ZIG_GLOBAL_CACHE_DIR: /host/build/cache/zig
build_requires:
  - sources/mkfs-xiafs-0.1.0.tar.gz
requires:
  - docker:builder/compiler/rust
provides:
  - bin/${HOST_ARCH}-linux-musl/mkfs.xiafs
---

# mkfs.xiafs

Static musl build of [bitplane/mkfs-xiafs](https://github.com/bitplane/mkfs-xiafs)
(Rust). Creates xiafs filesystem images.
