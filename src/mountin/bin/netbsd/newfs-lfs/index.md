---
title: NetBSD newfs_lfs
build_requires:
  - sources/netbsd-10.0-src.tgz
  - sources/netbsd-10.0-syssrc.tgz
provides:
  - bin/${MOUNTIN_TARGET_ARCH}-netbsd/newfs_lfs
---

# NetBSD LFS formatter

Static build of NetBSD's native LFS formatter. It is a test-data construction
tool and is not installed in the mountin appliance.
