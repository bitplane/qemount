---
title: PureDarwin mountin Appliance
env:
  BUILDER: builder/disk/qemu
  PUREDARWIN_IMAGE_SIZE: 48M
requires:
  - docker:builder/disk/qemu
  - guest/${OUTPUT_PLATFORM}/17.4/system
  - guest/${BUILD_ARCH}-linux/6.12/kernel
  - guest/${BUILD_ARCH}-linux/base/rootfs.img
  - bin/${OUTPUT_ARCH}-darwin/9d
  - bin/${OUTPUT_ARCH}-darwin/stream64
  - bin/${OUTPUT_ARCH}-darwin/mountin-init
provides:
  - bin/qemu/${OUTPUT_PLATFORM}/17.4/puredarwin.raw
---

# PureDarwin mountin Appliance

Builds a fresh 48 MiB MBR and HFS+ disk entirely from source-built outputs in
the matching PureDarwin toolbox.
The source-built GRUB XNU loader occupies the MBR and post-MBR gap. A minimal
Linux guest copies the BaseSystem tree onto HFS+ without requiring host mount
access.

mountin-init occupies XNU's fixed `/sbin/launchd` path, finds the first HFS,
HFS+ or HFSX volume on the one attached raw, MBR, GPT or APM image, mounts it
read-only and starts 9P directly. The appliance carries only the source-built
userland and kernel-extension closure needed for that path.
