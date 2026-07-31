---
title: Haiku Cross-Compiler
build_requires:
  - sources/haiku-qemount.tar.gz
provides:
  - docker:builder/compiler/haiku
---

# Haiku Cross-Compiler

Haiku build environment based on the official toolchain-worker image and the
qemount integration source.

Source is mounted during build via build_requires.
