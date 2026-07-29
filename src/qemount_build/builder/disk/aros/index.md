---
title: AROS Disk Builder
requires:
  - docker:builder/disk/alpine
provides:
  - docker:builder/disk/aros
---

# AROS Disk Builder

Runs AROS under QEMU for filesystem formats whose native creation tools are
only available inside the guest. `run-until-marker` bounds formatter runtime,
allows a short shutdown/flush grace period, and terminates emulators that do
not exit after AROS powers off.
