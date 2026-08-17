---
title: 9front mountin appliance
env:
  BUILDER: builder/disk/guest
output_platforms:
  x86_64-9front:
    requires:
      - guest/${OUTPUT_PLATFORM}/11957/9front.iso
    provides:
      - bin/qemu/${OUTPUT_PLATFORM}/11957/9front.iso
  aarch64-9front:
    requires:
      - guest/${OUTPUT_PLATFORM}/11957/9front.qcow2
      - guest/${OUTPUT_PLATFORM}/11957/u-boot.bin
    provides:
      - bin/qemu/${OUTPUT_PLATFORM}/11957/9front.qcow2
      - bin/qemu/${OUTPUT_PLATFORM}/11957/u-boot.bin
requires:
  - docker:${BUILDER}
---

# 9front mountin appliance

Publishes the reusable architecture-specific guest files as QEMU inputs.
