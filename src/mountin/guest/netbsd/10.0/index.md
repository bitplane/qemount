---
title: NetBSD 10.0 guest components
build_platforms:
  x86_64-linux: {}
  aarch64-linux: {}
output_platforms:
  x86_64-netbsd: {}
  aarch64-netbsd: {}
env:
  MOUNTIN_BUILDER: builder/compiler/netbsd/10.0/${MOUNTIN_TARGET_ARCH}
requires:
  - docker:${MOUNTIN_BUILDER}
---

# NetBSD 10.0 guest components
