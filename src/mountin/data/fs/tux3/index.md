---
format: fs/tux3
build_requires:
  - bin/${MOUNTIN_BUILD_ARCH}-linux-gnu/mkfs.tux3
requires:
  - docker:builder/disk/qemu
  - guest/${MOUNTIN_BUILD_ARCH}-linux/6.12/kernel
  - guest/${MOUNTIN_BUILD_ARCH}-linux/base/rootfs.img
  - data/templates/basic.tar
provides:
  - data/fs/basic.tux3
---

# Tux3 Test Image

Test image for the Tux3 filesystem.
