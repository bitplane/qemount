---
title: illumos guest system
output_platforms:
  x86_64-illumos:
    provides:
      - guest/${MOUNTIN_TARGET_PLATFORM}/2026-08-13/system
env:
  MOUNTIN_ILLUMOS_BUILDER: builder/compiler/illumos/2026-08-13
requires:
  - docker:${MOUNTIN_ILLUMOS_BUILDER}
---

# illumos guest system

Source-built kernel, boot closure, modules and runtime sysroot. Appliance
assembly consumes this reusable tree without recompiling illumos.
