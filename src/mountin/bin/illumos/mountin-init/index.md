---
title: mountin init for illumos
output_platforms:
  x86_64-illumos:
    provides:
      - bin/${MOUNTIN_TARGET_PLATFORM}/mountin-init
      - bin/${MOUNTIN_TARGET_PLATFORM}/mountin-bootstrap
env:
  MOUNTIN_BUILDER: builder/compiler/illumos/2026-08-13
requires:
  - docker:${MOUNTIN_BUILDER}
---

# mountin init for illumos

A freestanding bootstrap establishes the standard console descriptors before
executing the libc-based init. The latter owns disk discovery, filesystem
mounting and the serial 9P server lifecycle without requiring SMF or a
general-purpose userland.
