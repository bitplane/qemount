---
title: QEMU Disk Builder
build_requires:
  - sources/reiserfsprogs-3.6.27.tar.xz
  - sources/bcachefs-tools-1.20.0.tar.gz
  - bin/mkfs.sysv-${HOST_ARCH}
provides:
  - docker:builder/disk/qemu
---

# QEMU Disk Builder

Alpine-based image with QEMU and filesystem tools for building disk images
that require mount access. Includes mkfs utilities for various filesystems.

Sources are mounted during build via build_requires, not downloaded during
the Docker build.
