---
title: Haiku binaries
build_platforms:
  x86_64-linux: {}
  aarch64-linux: {}
output_platforms:
  x86_64-haiku:
    env:
      MOUNTIN_HAIKU_ARCH: x86_64
  aarch64-haiku:
    env:
      MOUNTIN_HAIKU_ARCH: arm64
env:
  MOUNTIN_BUILDER: builder/compiler/haiku/r1-beta6-hrev59919-1/${MOUNTIN_TARGET_ARCH}
requires:
  - docker:${MOUNTIN_BUILDER}
---

# Haiku binaries

Programs built for the Haiku appliance using the source-matched toolbox and
cross-development sysroot.
