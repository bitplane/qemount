---
title: mkfs.mfs
env:
  CARGO_HOME: /host/build/cache/cargo
  CARGO_TARGET_DIR: /host/build/cache/cargo-target
  ZIG_GLOBAL_CACHE_DIR: /host/build/cache/zig
build_requires:
  - sources/mkfs-mfs-0.1.0.tar.gz
requires:
  - docker:builder/compiler/rust
provides:
  - bin/${HOST_ARCH}-linux-musl/mkfs.mfs
---

# mkfs.mfs

Static musl build of [bitplane/mkfs-mfs](https://github.com/bitplane/mkfs-mfs)
(Rust). Creates Macintosh File System (MFS) disk images.
