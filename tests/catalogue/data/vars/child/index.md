---
title: Child
env:
  MOUNTIN_BUILDER: builder/${MOUNTIN_BUILD_ARCH}
requires:
  - docker:${MOUNTIN_BUILDER}
provides:
  - output/${MOUNTIN_TARGET_ARCH}/thing
---

# Child

Defines MOUNTIN_BUILDER from inherited MOUNTIN_BUILD_ARCH.
