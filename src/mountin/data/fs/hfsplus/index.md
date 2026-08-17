---
format: fs/hfsplus
requires:
  - docker:builder/disk/qemu
  - data/templates/basic.tar
  - guest/${BUILD_ARCH}-linux/6.12/kernel
  - guest/${BUILD_ARCH}-linux/base/rootfs.img
provides:
  - data/fs/basic.hfsplus
---

# hfsplus Test Image

Test image for the hfsplus filesystem.
