---
title: NetBSD mountin userspace
build_requires:
  - sources/netbsd-10.0-src.tgz
  - sources/netbsd-10.0-syssrc.tgz
  - sources/netbsd-10.0-sharesrc.tgz
provides:
  - bin/${MOUNTIN_TARGET_ARCH}-netbsd/mountin-rescue
  - bin/${MOUNTIN_TARGET_ARCH}-netbsd/mountin-fwcfg
  - share/${MOUNTIN_TARGET_ARCH}-netbsd/mountin-devices.mtree
---

# NetBSD mountin userspace

The small, statically linked command set used by the NetBSD appliance. It is
built with NetBSD's own crunchgen machinery rather than copied from the full
distribution rescue image.
