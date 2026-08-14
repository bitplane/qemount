---
title: illumos qemount sysroot
output_platforms:
  x86_64-illumos:
    provides:
      - bin/qemu/${OUTPUT_PLATFORM}/illumos/qemount/sysroot
env:
  BUILDER: builder/compiler/illumos
requires:
  - docker:${BUILDER}
---

# illumos qemount sysroot

The target headers, startup objects, runtime linker and C libraries required
to build qemount appliance programs. They are built directly from illumos-gate
rather than copied from a binary distribution or a complete proto area.
