---
format: fs/bcachefs
requires:
  - docker:builder/disk/qemu
  - data/templates/basic.tar
  - guest/${BUILD_ARCH}-linux/6.12/kernel
  - guest/${BUILD_ARCH}-linux/base/rootfs.img
provides:
  - data/fs/basic.bcachefs
---

# bcachefs Test Image

Test image for the bcachefs filesystem.
