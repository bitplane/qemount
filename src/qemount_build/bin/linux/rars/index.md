---
title: rars
env:
  CARGO_HOME: /host/build/cache/cargo
  CARGO_TARGET_DIR: /host/build/cache/cargo-target
  ZIG_GLOBAL_CACHE_DIR: /host/build/cache/zig
build_requires:
  - sources/rars-0.4.7.tar.gz
requires:
  - docker:builder/compiler/rust
provides:
  - bin/${HOST_ARCH}-linux-musl/rars
---

# rars

Static musl build of [rars-cli](https://github.com/bitplane/rars), used to
create RAR test fixtures without the proprietary `rar` program.
