---
title: NetBSD 10.0 Compiler
build_platforms:
  x86_64-linux: {}
env:
  OUTPUT_ARCH: x86_64
build_requires:
  - sources/netbsd-10.0-src.tgz
  - sources/netbsd-10.0-syssrc.tgz
  - sources/netbsd-10.0-sharesrc.tgz
  - sources/netbsd-10.0-gnusrc.tgz
provides:
  - docker:builder/compiler/netbsd/10.0
---

# NetBSD 10.0 Compiler

Cross-compiler for NetBSD 10.0, built using NetBSD's build.sh. Includes
full distribution build with rescue binaries needed for ramdisk images. The
tools and object trees are retained in the build cache and copied into the
resulting compiler image.

Architecture mapping:
- x86_64 → amd64/x86_64
- aarch64 → evbarm/aarch64
