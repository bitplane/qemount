---
title: illumos mountin appliance
output_platforms:
  x86_64-illumos:
    provides:
      - bin/qemu/${OUTPUT_PLATFORM}/2026-08-13/kernel
      - bin/qemu/${OUTPUT_PLATFORM}/2026-08-13/rootfs.iso
env:
  BUILDER: builder/disk/guest
requires:
  - docker:${BUILDER}
  - guest/${OUTPUT_PLATFORM}/2026-08-13/system
  - bin/${OUTPUT_PLATFORM}/mountin-init
  - bin/${OUTPUT_PLATFORM}/mountin-bootstrap
  - bin/${OUTPUT_PLATFORM}/9d
---

# illumos mountin appliance

Assembles the reusable illumos system with mountin init and 9d into the kernel
and read-only HSFS image consumed by QEMU.
