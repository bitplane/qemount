---
title: AROS PC i386 Base Guest
requires:
  - sources/aros-2026-07-30.tar.gz
  - sources/aros-ports/acpica-unix-20260408.tar.gz
  - sources/aros-ports/grub-2.12.tar.gz
  - sources/aros-ports/pci.ids
provides:
  - guest/${OUTPUT_ARCH}-aros/2026-07-30/aros.iso
---

# AROS PC i386 Base Guest

Builds only the AROS targets used by mountin and produces a fixture-capable base
ISO. The final mountin appliance adds its guest programs without rebuilding
AROS; those programs use the matching compiler toolbox directly.
