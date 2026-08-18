---
title: illumos UFS formatter
output_platforms:
  x86_64-illumos:
    provides:
      - bin/${MOUNTIN_TARGET_PLATFORM}/mkfs.ufs
env:
  MOUNTIN_BUILDER: builder/compiler/illumos/2026-08-13
requires:
  - docker:${MOUNTIN_BUILDER}
---

# illumos UFS formatter

The illumos UFS `mkfs` built for the fixture-generation guest. Interfaces for
disk labels and existing logging filesystems are omitted because the builder
only formats a new, explicitly-sized raw block device.
