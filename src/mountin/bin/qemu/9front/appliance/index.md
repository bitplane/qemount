---
title: 9front mountin appliance
env:
  BUILDER: builder/disk/guest
output_platforms:
  x86_64-9front:
    requires:
      - guest/${TARGET_PLATFORM}/11957/9front.iso
    provides:
      - bin/qemu/${TARGET_PLATFORM}/11957/9front.iso
  aarch64-9front:
    requires:
      - guest/${TARGET_PLATFORM}/11957/9front.qcow2
      - guest/${TARGET_PLATFORM}/11957/u-boot.bin
    provides:
      - bin/qemu/${TARGET_PLATFORM}/11957/9front.qcow2
      - bin/qemu/${TARGET_PLATFORM}/11957/u-boot.bin
requires:
  - docker:${BUILDER}
---

# 9front mountin appliance

Publishes the reusable architecture-specific guest files as QEMU inputs.
