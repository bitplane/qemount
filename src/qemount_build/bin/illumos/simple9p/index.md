---
title: simple9p for illumos
output_platforms:
  x86_64-illumos:
    provides:
      - bin/${OUTPUT_PLATFORM}/simple9p
env:
  BUILDER: builder/compiler/illumos/qemount-0.1
requires:
  - docker:${BUILDER}
  - sources/simple9p-0.6.2.tar.xz
---

# simple9p for illumos

Networkless illumos build of simple9p for the qemount appliance. It is compiled
against the matching sysroot carried by the versioned illumos toolbox.
