---
title: AROS PC i386 Guest
output_platforms:
  i386-aros: {}
env:
  MOUNTIN_AROS_TARGET: pc-i386
  MOUNTIN_AROS_VARIANT: tiny
  MOUNTIN_BUILDER: builder/compiler/aros/2026-07-30/pc-i386
requires:
  - docker:${MOUNTIN_BUILDER}
---

# AROS PC i386 Guest

Minimal 32-bit x86 AROS guest built as a bootable ISO. Filesystem and transport
capabilities will be declared after they work in the guest image.
