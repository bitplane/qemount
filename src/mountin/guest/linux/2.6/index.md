---
title: Linux 2.6 guest components
-output_platforms: true
output_platforms:
  x86_64-linux: {}
-build_platforms: true
build_platforms:
  x86_64-linux: {}
  aarch64-linux: {}
env:
  MOUNTIN_BUILDER: builder/compiler/linux/2
requires:
  - docker:${MOUNTIN_BUILDER}
---

# Linux 2.6 guest components
