---
title: PureDarwin 17.4 Bootstrap Image
env:
  BUILDER: builder/disk/debian
requires:
  - docker:builder/disk/debian
  - sources/puredarwin-17.4.vmdk.xz
provides:
  - bin/qemu/${ARCH}-darwin/puredarwin/bootstrap/puredarwin.raw
---

# PureDarwin 17.4 Bootstrap Image

Converts PureDarwin's published minimal VMDK into the raw block-device format
used by qemount. The virtual disk contents are not modified. This gives the
source-built guest a known bootloader and userland substrate while those
components are brought under the qemount build independently.

The bootstrap image is an implementation input, not the final qemount guest.
