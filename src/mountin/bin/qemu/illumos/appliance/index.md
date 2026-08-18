---
title: illumos mountin appliance
output_platforms:
  x86_64-illumos:
    provides:
      - bin/qemu/${TARGET_PLATFORM}/2026-08-13/kernel
      - bin/qemu/${TARGET_PLATFORM}/2026-08-13/rootfs.iso
env:
  BUILDER: builder/disk/guest
requires:
  - docker:${BUILDER}
  - guest/${TARGET_PLATFORM}/2026-08-13/system
  - bin/${TARGET_PLATFORM}/mountin-init
  - bin/${TARGET_PLATFORM}/mountin-bootstrap
  - bin/${TARGET_PLATFORM}/9d
---

# illumos mountin appliance

Assembles the reusable illumos system with mountin init and 9d into the kernel
and read-only HSFS image consumed by QEMU.
