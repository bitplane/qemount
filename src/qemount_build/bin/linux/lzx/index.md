---
title: lzx
env:
  CARGO_HOME: /host/build/cache/cargo
  CARGO_TARGET_DIR: /host/build/cache/cargo-target
  ZIG_GLOBAL_CACHE_DIR: /host/build/cache/zig
build_requires:
  - sources/amiga-lzx-cli-0.1.1.tar.gz
requires:
  - docker:builder/compiler/rust
provides:
  - bin/${HOST_ARCH}-linux-musl/lzx
---

# lzx

Static musl build of `amiga-lzx-cli`, used to create Amiga LZX test fixtures.
