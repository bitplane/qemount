---
title: NetBSD 10.0 Guest
build_platforms:
  x86_64-linux: {}
output_platforms:
  x86_64-netbsd: {}
env:
  BUILDER: builder/compiler/netbsd/10.0
requires:
  - docker:${BUILDER}
---

# NetBSD 10.0 Guest

NetBSD 10.0 components for qemount QEMU guest.
