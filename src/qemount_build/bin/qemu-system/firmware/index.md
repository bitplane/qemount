---
title: QEMU PC Firmware
env:
  BUILDER: builder/disk/debian
requires:
  - docker:builder/disk/debian
  - sources/qemu-10.2.0.tar.xz
provides:
  - bin/qemu-system/firmware/bios-256k.bin
  - bin/qemu-system/firmware/vgabios-stdvga.bin
  - bin/qemu-system/firmware/kvmvapic.bin
---

# QEMU PC Firmware

Firmware blobs shipped in the pinned QEMU source release for booting legacy PC
guests. They are separate from the emulator executables because direct-kernel
guests do not need them.
