---
title: Linux 6.x Compiler
build_platforms:
  x86_64-linux: {}
  aarch64-linux: {}
output_platforms:
  x86_64-linux-musl:
    provides:
      - docker:builder/compiler/linux/6/x86_64
  aarch64-linux-musl:
    provides:
      - docker:builder/compiler/linux/6/aarch64
execution_env:
  MOUNTIN_BUILD_JOBS: ${MOUNTIN_BUILD_JOBS}
requires:
  - docker:builder/compiler/linux
build_requires:
  - sources/musl-cross-make-2026-08-20.tar.gz
  - sources/gcc-9.4.0.tar.xz
  - sources/binutils-2.44.tar.gz
  - sources/musl-1.2.6.tar.gz
  - sources/gmp-6.3.0.tar.xz
  - sources/mpc-1.3.1.tar.gz
  - sources/mpfr-4.2.2.tar.xz
  - sources/linux-6.12.tar.xz
---

# Linux 6.x Compiler

Relocatable GCC, binutils and musl cross-toolbox built entirely from declared
sources. Either supported Linux host can build either target. Native builds use
the same target-prefixed tools as cross-builds, keeping consumers independent
of the host architecture.
