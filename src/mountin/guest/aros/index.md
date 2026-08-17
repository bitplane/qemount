---
title: AROS guest components
output_platforms:
  i386-aros: {}
env:
  AROS_TARGET: pc-i386
  AROS_VARIANT: tiny
  BUILDER: builder/compiler/aros/2026-07-30/pc-i386
requires:
  - docker:${BUILDER}
---

# AROS guest components
