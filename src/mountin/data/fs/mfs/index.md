---
format: fs/mfs
build_requires:
  - bin/${BUILD_ARCH}-linux-musl/mkfs.mfs
requires:
  - docker:builder/disk/qemu
  - guest/${BUILD_ARCH}-linux/6.12/kernel
  - guest/${BUILD_ARCH}-linux/base/rootfs.img
  - data/templates/basic.tar
provides:
  - data/fs/basic.mfs
---

# MFS Test Image

Test image for the Macintosh File System (MFS).
