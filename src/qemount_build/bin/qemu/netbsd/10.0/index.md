---
title: NetBSD 10.0 Guest
env:
  BUILDER: builder/compiler/netbsd/10.0:${HOST_ARCH}
requires:
  - docker:${BUILDER}
---

# NetBSD 10.0 Guest

NetBSD 10.0 components for qemount QEMU guest.
