---
title: PureDarwin Disk Builder
env:
  BUILDER: builder/disk/debian
requires:
  - docker:builder/disk/debian
provides:
  - docker:builder/disk/puredarwin
---

# PureDarwin Disk Builder

Rootless disk-image environment with a serial provisioning controller for
booting PureDarwin under the pinned qemount QEMU. The controller can modify a
boot disk directly or keep it in snapshot mode while constructing a second
disk.
