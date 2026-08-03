---
title: mkfs.sysv
env:
  CARGO_HOME: /host/build/cache/cargo
  CARGO_TARGET_DIR: /host/build/cache/cargo-target/${BUILD_PLATFORM}
  ZIG_GLOBAL_CACHE_DIR: /host/build/cache/zig/${BUILD_PLATFORM}
build_requires:
  - sources/mkfs-sysv-0.1.0.tar.gz
requires:
  - docker:builder/compiler/rust
provides:
  - bin/${OUTPUT_ARCH}-linux-musl/mkfs.sysv
---

# mkfs.sysv

Static musl build of [bitplane/mkfs-sysv](https://github.com/bitplane/mkfs-sysv)
(Rust). Creates SVR4 (System V) filesystem images.
