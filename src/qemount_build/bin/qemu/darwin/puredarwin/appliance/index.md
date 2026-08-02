---
title: PureDarwin qemount Appliance
env:
  BUILDER: builder/disk/puredarwin
  PUREDARWIN_IMAGE_SIZE: 256M
requires:
  - docker:builder/disk/puredarwin
  - bin/qemu-system/x86_64-linux-musl/qemu-system-x86_64
  - bin/qemu-system/firmware/bios-256k.bin
  - bin/qemu-system/firmware/vgabios-stdvga.bin
  - bin/qemu-system/firmware/kvmvapic.bin
  - bin/${ARCH}-darwin/simple9p
  - bin/${ARCH}-darwin/stream64
  - bin/qemu/${ARCH}-darwin/puredarwin/bootstrap-minimal/puredarwin.raw
provides:
  - bin/qemu/${ARCH}-darwin/puredarwin/appliance/puredarwin.raw
---

# PureDarwin qemount Appliance

Builds a fresh 256 MiB MBR and journaled HFS+ disk from the minimized
PureDarwin compatibility substrate. Darwin formats and populates its own root
filesystem so ownership, modes, links and HFS+ metadata are preserved. The
host installs the published image's generic Chameleon boot stages after the
new volume has been unmounted cleanly.

A temporary HFS payload disk carries simple9p and stream64 into the guest
during provisioning. It is not part of the published appliance. The published
PureDarwin kernel and driver set remain together as their matching compatibility
substrate.
