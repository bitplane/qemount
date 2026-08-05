---
title: DragonFly BSD 6.4.2 system
output_platforms:
  x86_64-dragonfly:
    provides:
      - bin/qemu/${OUTPUT_PLATFORM}/6.4.2/system/dragonfly.iso
---

# DragonFly BSD 6.4.2 system

Source-built live ISO for preserving the proven DragonFly compatibility
baseline. DragonFly world and the generic kernel are built from the pinned
source tree, then development files, the native toolchain and unrelated kernel
modules are excluded from the serial appliance.

The generic kernel and normal DragonFly startup remain intact in this pass so
filesystem behaviour stays comparable with the full image. They can be reduced
independently after the pruned image passes the same end-to-end tests.
