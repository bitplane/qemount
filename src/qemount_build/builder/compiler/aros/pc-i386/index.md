---
title: AROS PC i386 Cross-Compiler
env:
  BUILDER: builder/compiler/aros
  JOBS: ${JOBS}
requires:
  - docker:${BUILDER}
build_requires:
  - sources/aros-qemount-develop.tar.gz
provides:
  - docker:builder/compiler/aros/pc-i386
---

# AROS PC i386 Cross-Compiler

AROS's GCC and binutils cross-toolchain for native 32-bit x86 PC guests.
The image is tied to the selected AROS source revision and is cached
independently of guest-image assembly.
