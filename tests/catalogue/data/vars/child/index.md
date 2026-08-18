---
title: Child
env:
  BUILDER: builder/${BUILD_ARCH}
requires:
  - docker:${BUILDER}
provides:
  - output/${TARGET_ARCH}/thing
---

# Child

Defines BUILDER from inherited BUILD_ARCH.
