---
title: mkfs.xiafs
requires:
  - docker:builder/compiler/linux/6
provides:
  - bin/${HOST_ARCH}-linux-musl/mkfs.xiafs
---

# mkfs.xiafs

Minimal xiafs filesystem image creator. Creates xiafs images for testing,
based on Q. Frank Xia's original mkxfs (1992) and the modern-xiafs kernel
module. Xiafs was an early Linux filesystem (1993-1997).
