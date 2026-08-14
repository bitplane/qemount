---
title: illumos qemount kernel
output_platforms:
  x86_64-illumos:
    provides:
      - bin/qemu/${OUTPUT_PLATFORM}/illumos/qemount/kernel/genunix
      - bin/qemu/${OUTPUT_PLATFORM}/illumos/qemount/kernel/unix
env:
  BUILDER: builder/compiler/illumos
requires:
  - docker:${BUILDER}
---

# illumos qemount kernel

The platform kernel and common `genunix` module built from source on Linux.
Drivers and filesystem modules are selected by the appliance rather than by a
full illumos world build.
