---
title: 9pfuse
requires:
  - docker:${MOUNTIN_BUILDER}
  - sources/9pfuse-mountin-2026-08-15.tar.gz
  - sources/fuse-2.9.9.tar.gz
provides:
  - bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/9pfuse
---

# 9pfuse

Static build of 9pfuse - a FUSE client for the 9P protocol. Its `-n` option
limits the number of outstanding requests for constrained transports.
