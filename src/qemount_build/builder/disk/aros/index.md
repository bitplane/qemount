---
title: AROS Disk Builder
requires:
  - docker:builder/disk/alpine
provides:
  - docker:builder/disk/aros
---

# AROS Disk Builder

Runs AROS under QEMU for filesystem formats whose native creation tools are
only available inside the guest.
