---
title: strace
requires:
  - docker:${BUILDER}
  - sources/strace-6.7.tar.xz
provides:
  - bin/${TARGET_ARCH}-linux-${ENV}/strace
---

# strace

Debug tool for tracing system calls. Not required for mountin operation.

Only works with Linux 6.x kernels due to kernel API changes - won't work in
the 2.6 guest.
