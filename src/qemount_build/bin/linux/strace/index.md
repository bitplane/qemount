---
title: strace
requires:
  - sources/strace-6.7.tar.xz
provides:
  - bin/linux-${ARCH}/strace/strace
---

# strace

Debug tool for tracing system calls. Not required for qemount operation.

Only works with Linux 6.x kernels due to kernel API changes - won't work in
the 2.6 guest.
