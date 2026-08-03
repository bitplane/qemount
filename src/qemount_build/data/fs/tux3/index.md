---
format: fs/tux3
build_requires:
  - bin/${BUILD_ARCH}-linux-gnu/mkfs.tux3
requires:
  - docker:builder/disk/qemu
  - bin/qemu/${BUILD_ARCH}-linux/6.12/boot/kernel
  - bin/qemu/${BUILD_ARCH}-linux/6.12/boot/rootfs.img
  - data/templates/basic.tar
provides:
  - data/fs/basic.tux3
---

# Tux3 Test Image

Test image for the Tux3 filesystem.
