---
format: fs/minix
requires:
  - docker:builder/disk/qemu
  - data/templates/basic.tar
  - bin/qemu/${HOST_ARCH}-linux/6.17/boot/kernel
  - bin/qemu/${HOST_ARCH}-linux/6.17/boot/rootfs.img
provides:
  - data/fs/basic.minix
---

# minix Test Image

Test image for the minix filesystem.
