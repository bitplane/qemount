---
title: AROS binaries
output_platforms:
  i386-aros: {}
env:
  MOUNTIN_BUILDER: builder/compiler/aros/2026-07-30/pc-i386
requires:
  - docker:${MOUNTIN_BUILDER}
---

# AROS binaries

Programs built for 32-bit x86 AROS guests using the Developer tree in the
matching source-pinned compiler toolbox.
