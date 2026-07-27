---
title: AROS PC i386 System
requires:
  - sources/aros-qemount.tar.gz
provides:
  - bin/qemu/${ARCH}-aros/system/aros.iso
  - lib/${ARCH}-aros/sdk.tar.gz
---

# AROS PC i386 System

Builds the tiny-variant AROS system once, producing both its bootable base ISO
and the matching Developer SDK. Guest programs consume the SDK, and the final
guest image adds those programs to the base ISO without rebuilding AROS.
