---
format: fs/jfs
requires:
  - docker:builder/disk/qemu
  - data/templates/basic.tar
  - bin/qemu/linux-${HOST_ARCH}/6.17/boot/kernel
  - bin/qemu/linux-${HOST_ARCH}/6.17/boot/rootfs.img
provides:
  - data/fs/basic.jfs
---

# jfs Test Image

Test image for the jfs filesystem.
