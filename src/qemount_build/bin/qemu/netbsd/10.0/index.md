---
title: NetBSD 10.0 Guest
env:
  BUILDER: builder/compiler/netbsd:${HOST_ARCH}
requires:
  - docker:${BUILDER}
---

# NetBSD 10.0 Guest

NetBSD 10.0 components for qemount QEMU guest.
