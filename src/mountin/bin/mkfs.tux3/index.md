---
title: mkfs.tux3
build_platforms:
  x86_64-linux: {}
  aarch64-linux: {}
output_platforms:
  x86_64-linux-gnu:
    build_platforms:
      x86_64-linux: {}
  aarch64-linux-gnu:
    build_platforms:
      aarch64-linux: {}
build_requires:
  - sources/mkfs-tux3-2015.06.01.tar.gz
requires: []
provides:
  - bin/${MOUNTIN_TARGET_ARCH}-linux-gnu/mkfs.tux3
---

# mkfs.tux3

Static build of mkfs.tux3 from Daniel Phillips' Tux3 source, repackaged as
a self-contained tree (see `sources/mkfs-tux3-2015.06.01.md`). Built on
glibc (Debian) for compatibility with the upstream kernel-emulation shim
layer.
