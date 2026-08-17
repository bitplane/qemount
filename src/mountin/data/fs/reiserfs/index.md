---
format: fs/reiserfs
kernel: "6.12"
build_requires:
  - bin/${BUILD_ARCH}-linux-gnu/mkfs.reiserfs
requires:
  - docker:builder/disk/qemu
  - data/templates/basic.tar
  - guest/${BUILD_ARCH}-linux/6.12/kernel
  - guest/${BUILD_ARCH}-linux/base/rootfs.img
provides:
  - data/fs/basic.reiserfs
---

# reiserfs Test Image

Test image for the reiserfs filesystem.
