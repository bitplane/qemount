---
title: PureDarwin qemount Appliance
env:
  BUILDER: builder/disk/qemu
  PUREDARWIN_IMAGE_SIZE: 48M
requires:
  - docker:builder/disk/qemu
  - bin/qemu/${BUILD_ARCH}-linux/6.12/boot/kernel
  - bin/qemu/${BUILD_ARCH}-linux/6.12/boot/rootfs.img
  - bin/qemu/${OUTPUT_ARCH}-darwin/puredarwin/system/base-system.tar.gz
  - bin/qemu/${OUTPUT_ARCH}-darwin/puredarwin/boot/boot.img
  - bin/qemu/${OUTPUT_ARCH}-darwin/puredarwin/boot/core.img
  - bin/qemu/${OUTPUT_ARCH}-darwin/puredarwin/boot/efiemu64.o
  - bin/${OUTPUT_ARCH}-darwin/simple9p
  - bin/${OUTPUT_ARCH}-darwin/stream64
  - bin/${OUTPUT_ARCH}-darwin/qemount-init
provides:
  - bin/qemu/${OUTPUT_ARCH}-darwin/puredarwin/appliance/puredarwin.raw
---

# PureDarwin qemount Appliance

Builds a fresh 48 MiB MBR and HFS+ disk entirely from source-built outputs.
The source-built GRUB XNU loader occupies the MBR and post-MBR gap. A minimal
Linux guest copies the BaseSystem tree onto HFS+ without requiring host mount
access.

qemount-init occupies XNU's fixed `/sbin/launchd` path, finds the first HFS,
HFS+ or HFSX volume on the one attached raw, MBR, GPT or APM image, mounts it
read-only and starts 9P directly. The appliance carries only the source-built
userland and kernel-extension closure needed for that path.
