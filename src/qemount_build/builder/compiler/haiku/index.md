---
title: Haiku Cross-Compiler
build_platforms:
  x86_64-linux: {}
env:
  OUTPUT_ARCH: x86_64
build_requires:
  - sources/haiku-qemount-2026-08-01-2.tar.gz
provides:
  - docker:builder/compiler/haiku
---

# Haiku Cross-Compiler

Haiku build environment based on the official toolchain-worker image and the
qemount integration source.

Source is mounted during build via build_requires. The official toolchain-worker
and application SDK images are currently published for amd64 hosts only.
