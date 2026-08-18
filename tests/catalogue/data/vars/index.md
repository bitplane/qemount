---
title: Root
no_inherit:
  - provides
  - build_requires
env:
  MOUNTIN_BUILD_ARCH: ${MOUNTIN_BUILD_ARCH}
  MOUNTIN_TARGET_ARCH: ${MOUNTIN_TARGET_ARCH}
output_platforms:
  x86_64-test: {}
  aarch64-test: {}
---

# Root

Defines base env from external context.
