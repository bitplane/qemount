---
title: Child
env:
  BUILDER: builder/${HOST_ARCH}
requires:
  - docker:${BUILDER}
provides:
  - output/${ARCH}/thing
---

# Child

Defines BUILDER from inherited HOST_ARCH.
