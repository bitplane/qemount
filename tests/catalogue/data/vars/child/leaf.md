---
title: Leaf
requires:
  - docker:${MOUNTIN_BUILDER}
  - source.tar
provides:
  - output/${MOUNTIN_TARGET_ARCH}/leaf
---

# Leaf

Uses inherited MOUNTIN_BUILDER and MOUNTIN_TARGET_ARCH.
