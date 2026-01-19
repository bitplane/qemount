---
format: fs/xfs
requires:
  - docker:builder/disk/qemu
  - data/templates/basic.tar
  - bin/qemu/${HOST_ARCH}-linux/6.17/boot/kernel
  - bin/qemu/${HOST_ARCH}-linux/6.17/boot/rootfs.img
provides:
  - data/fs/basic.xfs
---

# xfs Test Image

Test image for the xfs filesystem.
