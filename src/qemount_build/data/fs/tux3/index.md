---
format: fs/tux3
build_requires:
  - bin/${HOST_ARCH}-linux-musl/mkfs.tux3
requires:
  - docker:builder/disk/qemu
  - bin/qemu/${HOST_ARCH}-linux/6.12/boot/kernel
  - bin/qemu/${HOST_ARCH}-linux/6.12/boot/rootfs.img
  - data/templates/basic.tar
provides:
  - data/fs/basic.tux3
---

# Tux3 Test Image

Test image for the Tux3 filesystem.
