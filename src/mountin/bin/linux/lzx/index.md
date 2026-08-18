---
title: lzx
build_requires:
  - sources/amiga-lzx-cli-0.1.1.tar.gz
requires:
  - docker:builder/compiler/rust
provides:
  - bin/${MOUNTIN_TARGET_ARCH}-linux-musl/lzx
---

# lzx

Static musl build of `amiga-lzx-cli`, used to create Amiga LZX test fixtures.
