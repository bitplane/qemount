---
format: fs/jfs
requires:
  - docker:builder/disk/qemu
  - data/templates/basic.tar
  - bin/qemu/${HOST_ARCH}-linux/6.17/boot/kernel
  - bin/qemu/${HOST_ARCH}-linux/6.17/boot/rootfs.img
provides:
  - data/fs/basic.jfs
---

# jfs Test Image

Test image for the jfs filesystem.
