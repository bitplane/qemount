---
format: fs/reiser4
build_requires:
  - bin/${BUILD_ARCH}-linux-gnu/mkfs.reiser4
  - bin/${BUILD_ARCH}-linux-gnu/reiser4-busy
requires:
  - docker:builder/disk/qemu
  - bin/qemu/${BUILD_ARCH}-linux/6.12/boot/kernel
  - bin/qemu/${BUILD_ARCH}-linux/6.12/boot/rootfs.img
  - data/templates/basic.tar
provides:
  - data/fs/basic.reiser4
---

# Reiser4 Test Image

Test image for the Reiser4 filesystem.
