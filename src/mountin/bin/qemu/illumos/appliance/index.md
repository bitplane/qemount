---
title: illumos mountin appliance
output_platforms:
  x86_64-illumos:
    provides:
      - bin/qemu/${MOUNTIN_TARGET_PLATFORM}/2026-08-13/kernel
      - bin/qemu/${MOUNTIN_TARGET_PLATFORM}/2026-08-13/rootfs.iso
env:
  MOUNTIN_BUILDER: builder/disk/guest
requires:
  - docker:${MOUNTIN_BUILDER}
  - guest/${MOUNTIN_TARGET_PLATFORM}/2026-08-13/system
  - bin/${MOUNTIN_TARGET_PLATFORM}/mountin-init
  - bin/${MOUNTIN_TARGET_PLATFORM}/mountin-bootstrap
  - bin/${MOUNTIN_TARGET_PLATFORM}/9d
---

# illumos mountin appliance

Assembles the reusable illumos system with mountin init and 9d into the kernel
and read-only HSFS image consumed by QEMU.
