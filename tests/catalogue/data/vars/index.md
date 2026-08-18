---
title: Root
no_inherit:
  - provides
  - build_requires
env:
  BUILD_ARCH: ${BUILD_ARCH}
  TARGET_ARCH: ${TARGET_ARCH}
output_platforms:
  x86_64-test: {}
  aarch64-test: {}
---

# Root

Defines base env from external context.
