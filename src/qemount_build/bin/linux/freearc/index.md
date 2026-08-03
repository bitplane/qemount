---
title: FreeArc
-output_platforms: true
output_platforms:
  x86_64-linux-gnu:
    build_platforms:
      x86_64-linux: {}
  aarch64-linux-gnu:
    build_platforms:
      aarch64-linux: {}
build_requires:
  - sources/FreeArc-0.51-sources.tar.bz2
requires:
  - docker:builder/compiler/freearc
provides:
  - bin/${OUTPUT_ARCH}-linux-gnu/freearc
---

# FreeArc

Native build of FreeArc 0.51 used to create FreeArc test fixtures.
