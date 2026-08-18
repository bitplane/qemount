---
format: fs/hfsplus
requires:
  - docker:builder/disk/qemu
  - data/templates/basic.tar
  - guest/${MOUNTIN_BUILD_ARCH}-linux/6.12/kernel
  - guest/${MOUNTIN_BUILD_ARCH}-linux/base/rootfs.img
provides:
  - data/fs/basic.hfsplus
---

# hfsplus Test Image

Test image for the hfsplus filesystem.
