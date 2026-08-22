---
title: AROS guest components
output_platforms:
  i386-aros: {}
env:
  MOUNTIN_AROS_TARGET: pc-i386
  MOUNTIN_AROS_VARIANT: tiny
  MOUNTIN_BUILDER: builder/compiler/aros/2026-08-21/pc-i386
requires:
  - docker:${MOUNTIN_BUILDER}
---

# AROS guest components
