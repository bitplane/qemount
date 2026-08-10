---
title: AROS PC i386 System
requires:
  - sources/aros-qemount-2026-07-30.tar.gz
  - sources/aros-ports/acpica-unix-20260408.tar.gz
  - sources/aros-ports/grub-2.12.tar.gz
  - sources/aros-ports/pci.ids
provides:
  - bin/qemu/${OUTPUT_ARCH}-aros/system/aros.iso
  - lib/${OUTPUT_ARCH}-aros/sdk.tar.gz
---

# AROS PC i386 System

Builds only the AROS targets used by qemount, producing a fixture-capable base
ISO and the matching qemount Developer SDK. Guest programs consume that SDK,
and the final guest image adds them to the base ISO without rebuilding AROS.
