---
title: illumos UFS fixture init
output_platforms:
  x86_64-illumos:
    provides:
      - bin/${MOUNTIN_TARGET_PLATFORM}/ufs-fixture-init
env:
  MOUNTIN_BUILDER: builder/compiler/illumos/2026-08-13
requires:
  - docker:${MOUNTIN_BUILDER}
---

# illumos UFS fixture init

Minimal fixture-only init which formats the attached disk with illumos `mkfs`,
copies the standard test tree into it, verifies the result, and unmounts it.
