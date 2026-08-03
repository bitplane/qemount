---
title: AROS binaries
output_platforms:
  i386-aros: {}
env:
  BUILDER: builder/compiler/aros/pc-i386
requires:
  - docker:${BUILDER}
---

# AROS binaries

Programs built for 32-bit x86 AROS guests using the SDK produced by the
matching source-pinned system build.
