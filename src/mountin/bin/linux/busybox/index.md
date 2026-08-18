---
title: BusyBox
requires:
  - docker:${MOUNTIN_BUILDER}
  - sources/busybox-1.36.1.tar.bz2
provides:
  - bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/busybox
---

# BusyBox

Static build of busybox with mountin-specific config.
