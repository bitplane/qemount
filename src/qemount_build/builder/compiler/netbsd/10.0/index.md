---
title: NetBSD 10.0 Compiler
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
full distribution build with rescue binaries needed for ramdisk images.

Architecture mapping:
- x86_64 → amd64
- aarch64 → evbarm
