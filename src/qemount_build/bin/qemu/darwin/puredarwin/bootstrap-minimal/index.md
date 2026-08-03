---
title: Minimal PureDarwin 17.4 Bootstrap
env:
  BUILDER: builder/disk/puredarwin
requires:
  - docker:builder/disk/puredarwin
  - bin/qemu-system/${BUILD_ARCH}-linux-musl/qemu-system-x86_64
  - bin/qemu-system/firmware/bios-256k.bin
  - bin/qemu-system/firmware/vgabios-stdvga.bin
  - bin/qemu-system/firmware/kvmvapic.bin
  - bin/qemu/${OUTPUT_ARCH}-darwin/puredarwin/bootstrap/puredarwin.raw
provides:
  - bin/qemu/${OUTPUT_ARCH}-darwin/puredarwin/bootstrap-minimal/puredarwin.raw
---

# Minimal PureDarwin 17.4 Bootstrap

Prunes the published PureDarwin image from inside a running Darwin guest. The
stage removes build tools, headers, documentation, search indexes and other
development residue while retaining the boot chain, kernel, drivers and
userland needed for the next appliance-building step.

This remains a Darwin 17.4 compatibility substrate. The source-built matching
kernel is installed by the appliance stage.
