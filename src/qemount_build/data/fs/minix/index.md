---
format: fs/minix
requires:
  - docker:builder/disk/qemu:${HOST_ARCH}
  - data/fs/basic.ext2
  - bin/qemu/linux-${HOST_ARCH}/6.17/boot/kernel
  - bin/qemu/linux-${HOST_ARCH}/6.17/boot/rootfs.img
provides:
  - data/fs/basic.minix
---

# minix Test Image

Test image for the minix filesystem.
