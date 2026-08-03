---
title: Haiku binaries
build_platforms:
  x86_64-linux: {}
output_platforms:
  x86_64-haiku: {}
env:
  BUILDER: builder/compiler/haiku/r1beta5-sdk
requires:
  - docker:${BUILDER}
---

# Haiku binaries

Programs built for 64-bit Haiku R1 Beta 5 guests using the matching official
cross-compiler and sysroot.
