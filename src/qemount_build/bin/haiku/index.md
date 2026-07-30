---
title: Haiku binaries
env:
  ARCH: x86_64
  BUILDER: builder/compiler/haiku/r1beta5-sdk
requires:
  - docker:${BUILDER}
---

# Haiku binaries

Programs built for 64-bit Haiku R1 Beta 5 guests using the matching official
cross-compiler and sysroot.

