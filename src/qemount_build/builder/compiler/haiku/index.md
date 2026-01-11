---
title: Haiku Cross-Compiler
build_requires:
  - sources/haiku-r1beta5.tar.gz
provides:
  - docker:builder/compiler/haiku:${HOST_ARCH}
---

# Haiku Cross-Compiler

Haiku OS cross-compiler based on the official toolchain-worker image.
Configured for R1 Beta 5.

Source is mounted during build via build_requires.
