---
title: illumos UFS formatter
output_platforms:
  x86_64-illumos:
    provides:
      - bin/${OUTPUT_PLATFORM}/mkfs.ufs
requires:
  - docker:builder/compiler/illumos
  - bin/qemu/${OUTPUT_PLATFORM}/illumos/qemount/sysroot
---

# illumos UFS formatter

The illumos UFS `mkfs` built for the fixture-generation guest. Interfaces for
disk labels and existing logging filesystems are omitted because the builder
only formats a new, explicitly-sized raw block device.
