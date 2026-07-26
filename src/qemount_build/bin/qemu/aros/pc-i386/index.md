---
title: AROS PC i386 Guest
env:
  ARCH: i386
  AROS_TARGET: pc-i386
  AROS_VARIANT: tiny
  BUILDER: builder/compiler/aros/pc-i386
requires:
  - docker:${BUILDER}
---

# AROS PC i386 Guest

Minimal 32-bit x86 AROS guest built as a bootable ISO. Filesystem and transport
capabilities will be declared after they work in the guest image.
