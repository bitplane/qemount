---
title: Haiku binaries
build_platforms:
  x86_64-linux: {}
output_platforms:
  x86_64-haiku: {}
env:
  BUILDER: builder/compiler/haiku/r1-beta6-hrev59919-1
requires:
  - docker:${BUILDER}
---

# Haiku binaries

Programs built for the Haiku appliance using the source-matched toolbox and
cross-development sysroot.
