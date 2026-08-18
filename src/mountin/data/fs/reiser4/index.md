---
format: fs/reiser4
build_requires:
  - bin/${MOUNTIN_BUILD_ARCH}-linux-gnu/mkfs.reiser4
  - bin/${MOUNTIN_BUILD_ARCH}-linux-gnu/reiser4-busy
requires:
  - docker:builder/disk/qemu
  - guest/${MOUNTIN_BUILD_ARCH}-linux/6.12/kernel
  - guest/${MOUNTIN_BUILD_ARCH}-linux/base/rootfs.img
  - data/templates/basic.tar
provides:
  - data/fs/basic.reiser4
---

# Reiser4 Test Image

Test image for the Reiser4 filesystem.
