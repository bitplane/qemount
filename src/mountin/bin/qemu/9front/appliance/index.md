---
title: 9front mountin appliance
env:
  MOUNTIN_BUILDER: builder/disk/guest
output_platforms:
  x86_64-9front:
    requires:
      - guest/${MOUNTIN_TARGET_PLATFORM}/11957/9front.iso
    provides:
      - bin/qemu/${MOUNTIN_TARGET_PLATFORM}/11957/9front.iso
  aarch64-9front:
    requires:
      - guest/${MOUNTIN_TARGET_PLATFORM}/11957/9front.qcow2
      - guest/${MOUNTIN_TARGET_PLATFORM}/11957/u-boot.bin
    provides:
      - bin/qemu/${MOUNTIN_TARGET_PLATFORM}/11957/9front.qcow2
      - bin/qemu/${MOUNTIN_TARGET_PLATFORM}/11957/u-boot.bin
requires:
  - docker:${MOUNTIN_BUILDER}
---

# 9front mountin appliance

Publishes the reusable architecture-specific guest files as QEMU inputs.
