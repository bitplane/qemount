---
title: mkfs.gemdos
env:
  CARGO_HOME: /host/build/cache/cargo
  CARGO_TARGET_DIR: /host/build/cache/cargo-target/${BUILD_PLATFORM}
  ZIG_GLOBAL_CACHE_DIR: /host/build/cache/zig/${BUILD_PLATFORM}
build_requires:
  - sources/mkfs-gemdos-0.1.0.tar.gz
requires:
  - docker:builder/compiler/rust
provides:
  - bin/${OUTPUT_ARCH}-linux-musl/mkfs.gemdos
---

# mkfs.gemdos

Static musl build of [bitplane/mkfs-gemdos](https://github.com/bitplane/mkfs-gemdos)
(Rust). Creates GEMDOS (Atari TOS) filesystem images.
