---
format: fs/f2fs
requires:
  - docker:builder/disk/qemu
  - data/templates/basic.tar
  - bin/qemu/${HOST_ARCH}-linux/6.17/boot/kernel
  - bin/qemu/${HOST_ARCH}-linux/6.17/boot/rootfs.img
provides:
  - data/fs/basic.f2fs
---

# f2fs Test Image

Test image for the f2fs filesystem.
