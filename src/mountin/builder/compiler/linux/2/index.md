---
title: Linux 2.6 Compiler
-build_platforms: true
build_platforms:
  x86_64-linux: {}
  aarch64-linux: {}
execution_env:
  MOUNTIN_BUILD_JOBS: ${MOUNTIN_BUILD_JOBS}
build_requires:
  - sources/musl-cross-make-2026-08-20.tar.gz
  - sources/gcc-5.3.0.tar.bz2
  - sources/binutils-2.25.1.tar.bz2
  - sources/musl-1.2.6.tar.gz
  - sources/gmp-6.3.0.tar.xz
  - sources/mpc-1.3.1.tar.gz
  - sources/mpfr-4.2.2.tar.xz
  - sources/linux-2.6.39.4.tar.xz
provides:
  - docker:builder/compiler/linux/2
---

# Linux 2.6 Compiler

Source-built GCC, binutils and musl cross-toolbox targeting x86_64 Linux.
Either supported Linux host can build the same Linux 2.6 guest artefacts.
