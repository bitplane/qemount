---
title: NetBSD binaries
build_platforms:
  x86_64-linux: {}
output_platforms:
  x86_64-netbsd: {}
env:
  BUILDER: builder/compiler/netbsd/10.0
requires:
  - docker:${BUILDER}
---

# NetBSD binaries

Binaries cross-compiled for NetBSD using the NetBSD toolchain.
