---
title: rars
build_requires:
  - sources/rars-0.4.7.tar.gz
requires:
  - docker:builder/compiler/rust
provides:
  - bin/${TARGET_ARCH}-linux-musl/rars
---

# rars

Static musl build of [rars-cli](https://github.com/bitplane/rars), used to
create RAR test fixtures without the proprietary `rar` program.
