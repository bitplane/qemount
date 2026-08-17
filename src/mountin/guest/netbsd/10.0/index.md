---
title: NetBSD 10.0 guest components
build_platforms:
  x86_64-linux: {}
  aarch64-linux: {}
output_platforms:
  x86_64-netbsd: {}
  aarch64-netbsd: {}
env:
  BUILDER: builder/compiler/netbsd/10.0/${OUTPUT_ARCH}
requires:
  - docker:${BUILDER}
---

# NetBSD 10.0 guest components
