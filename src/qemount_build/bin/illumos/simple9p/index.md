---
title: simple9p for illumos
output_platforms:
  x86_64-illumos:
    provides:
      - bin/${OUTPUT_PLATFORM}/simple9p
requires:
  - docker:builder/compiler/illumos
  - bin/qemu/${OUTPUT_PLATFORM}/illumos/qemount/sysroot
  - sources/simple9p-0.6.2.tar.xz
---

# simple9p for illumos

Networkless illumos build of simple9p for the qemount appliance. It serves the
mounted volume namespace over an already-connected serial byte stream.
