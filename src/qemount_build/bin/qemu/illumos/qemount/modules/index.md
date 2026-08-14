---
title: illumos qemount kernel modules
output_platforms:
  x86_64-illumos:
    provides:
      - bin/qemu/${OUTPUT_PLATFORM}/illumos/qemount/modules
env:
  BUILDER: builder/compiler/illumos
requires:
  - docker:${BUILDER}
  - bin/qemu/${OUTPUT_PLATFORM}/illumos/qemount/kernel/genunix
  - bin/qemu/${OUTPUT_PLATFORM}/illumos/qemount/kernel/unix
---

# illumos qemount kernel modules

The loadable modules required by the qemount appliance. This is intentionally
an appliance-owned closure rather than the complete illumos kernel module set.
