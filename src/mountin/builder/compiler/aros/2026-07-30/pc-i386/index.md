---
title: AROS 2026-07-30 PC i386 Cross-Compiler
env:
  MOUNTIN_BUILDER: builder/compiler/aros
execution_env:
  MOUNTIN_BUILD_JOBS: ${MOUNTIN_BUILD_JOBS}
requires:
  - docker:${MOUNTIN_BUILDER}
build_requires:
  - sources/aros-2026-07-30.tar.gz
  - sources/aros-ports/binutils-2.32.tar.bz2
  - sources/aros-ports/gcc-6.5.0.tar.xz
  - sources/aros-ports/gmp-6.3.0.tar.bz2
  - sources/aros-ports/isl-0.25.tar.bz2
  - sources/aros-ports/mpc-1.4.1.tar.xz
  - sources/aros-ports/mpfr-4.2.2.tar.bz2
provides:
  - docker:builder/compiler/aros/2026-07-30/pc-i386
---

# AROS 2026-07-30 PC i386 Cross-Compiler

AROS's GCC and binutils cross-toolchain and matching Developer tree for native
32-bit x86 PC guests. The image is tied to the selected AROS source revision
and is cached independently of guest-image assembly.

Consumers inherit `CC`, `AR`, `STRIP`, and `AROS_SYSROOT`. The compiler wrapper
supplies the matching Developer tree as its sysroot, so ordinary build systems
do not need to know the AROS toolchain or SDK layout.
