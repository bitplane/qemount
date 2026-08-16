---
title: NetBSD mountin userspace
build_requires:
  - sources/netbsd-10.0-src.tgz
  - sources/netbsd-10.0-syssrc.tgz
  - sources/netbsd-10.0-sharesrc.tgz
provides:
  - bin/${OUTPUT_ARCH}-netbsd/mountin-rescue
  - share/${OUTPUT_ARCH}-netbsd/mountin-devices.mtree
---

# NetBSD mountin userspace

The small, statically linked command set used by the NetBSD appliance. It is
built with NetBSD's own crunchgen machinery rather than copied from the full
distribution rescue image.
