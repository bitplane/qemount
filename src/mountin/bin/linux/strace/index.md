---
title: strace
requires:
  - docker:${MOUNTIN_BUILDER}
  - sources/strace-6.7.tar.xz
provides:
  - bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/strace
---

# strace

Debug tool for tracing system calls. Not required for mountin operation.

Only works with Linux 6.x kernels due to kernel API changes - won't work in
the 2.6 guest.
