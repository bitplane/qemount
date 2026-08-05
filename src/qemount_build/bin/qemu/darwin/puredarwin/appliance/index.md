---
title: PureDarwin qemount Appliance
env:
  BUILDER: builder/disk/puredarwin
  PUREDARWIN_IMAGE_SIZE: 48M
requires:
  - docker:builder/disk/puredarwin
  - bin/qemu-system/${BUILD_ARCH}-linux-musl/qemu-system-x86_64
  - bin/qemu-system/firmware/bios-256k.bin
  - bin/qemu-system/firmware/vgabios-stdvga.bin
  - bin/qemu-system/firmware/kvmvapic.bin
  - bin/${OUTPUT_ARCH}-darwin/simple9p
  - bin/${OUTPUT_ARCH}-darwin/stream64
  - bin/${OUTPUT_ARCH}-darwin/qemount-init
  - bin/qemu/${OUTPUT_ARCH}-darwin/puredarwin/bootstrap-minimal/puredarwin.raw
provides:
  - bin/qemu/${OUTPUT_ARCH}-darwin/puredarwin/appliance/puredarwin.raw
---

# PureDarwin qemount Appliance

Builds a fresh 48 MiB MBR and journaled HFS+ disk from an explicit appliance
manifest. Darwin formats and populates its own root filesystem so ownership,
modes, links and HFS+ metadata are preserved. The host installs the published
image's generic Chameleon boot stages after the new volume has been unmounted
cleanly.

A temporary HFS payload disk carries qemount-init, simple9p and stream64 into
the guest during provisioning. It is not part of the published appliance.
qemount-init occupies XNU's fixed `/sbin/launchd` path, finds the first HFS,
HFS+ or HFSX volume on the one attached raw, MBR, GPT or APM image, mounts it
read-only and starts 9P directly. The manifest includes only the userland and
kernel-extension closure needed for that path.
