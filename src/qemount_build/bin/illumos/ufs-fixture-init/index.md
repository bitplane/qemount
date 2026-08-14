---
title: illumos UFS fixture init
output_platforms:
  x86_64-illumos:
    provides:
      - bin/${OUTPUT_PLATFORM}/ufs-fixture-init
env:
  BUILDER: builder/compiler/illumos/qemount-0.1
requires:
  - docker:${BUILDER}
---

# illumos UFS fixture init

Minimal fixture-only init which formats the attached disk with illumos `mkfs`,
copies the standard test tree into it, verifies the result, and unmounts it.
