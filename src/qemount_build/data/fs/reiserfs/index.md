---
format: fs/reiserfs
kernel: "2.6"
build_requires:
  - bin/${BUILD_ARCH}-linux-gnu/mkfs.reiserfs
requires:
  - docker:builder/disk/qemu
  - data/templates/basic.tar
  - bin/qemu/${BUILD_ARCH}-linux/2.6/boot/kernel
  - bin/qemu/${BUILD_ARCH}-linux/2.6/boot/rootfs.img
provides:
  - data/fs/basic.reiserfs
---

# reiserfs Test Image

Test image for the reiserfs filesystem.
