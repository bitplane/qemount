---
title: rars
env:
  CARGO_HOME: /host/build/cache/cargo
  CARGO_TARGET_DIR: /host/build/cache/cargo-target/${BUILD_PLATFORM}
  ZIG_GLOBAL_CACHE_DIR: /host/build/cache/zig/${BUILD_PLATFORM}
build_requires:
  - sources/rars-0.4.7.tar.gz
requires:
  - docker:builder/compiler/rust
provides:
  - bin/${OUTPUT_ARCH}-linux-musl/rars
---

# rars

Static musl build of [rars-cli](https://github.com/bitplane/rars), used to
create RAR test fixtures without the proprietary `rar` program.
