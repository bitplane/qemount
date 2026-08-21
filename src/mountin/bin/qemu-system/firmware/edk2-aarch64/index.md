---
title: QEMU AArch64 UEFI Firmware
requires:
  - sources/qemu-10.2.0.tar.xz
provides:
  - bin/qemu-system/firmware/edk2-aarch64-code.fd
build_platforms:
  - x86_64-linux
  - aarch64-linux
---

# QEMU AArch64 UEFI Firmware

Builds the ArmVirt AArch64 EDK2 firmware from the complete source closure
vendored in the pinned QEMU release. The same firmware boots AArch64 guests on
either Linux host architecture.
