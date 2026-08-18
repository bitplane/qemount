---
title: NetBSD binaries
build_platforms:
  x86_64-linux: {}
  aarch64-linux: {}
output_platforms:
  x86_64-netbsd: {}
  aarch64-netbsd: {}
env:
  BUILDER: builder/compiler/netbsd/10.0/${TARGET_ARCH}
requires:
  - docker:${BUILDER}
---

# NetBSD binaries

Binaries cross-compiled for NetBSD using the NetBSD toolchain.
