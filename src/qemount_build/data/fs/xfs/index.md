---
format: fs/xfs
requires:
  - docker:builder/qemu-builder:${HOST_ARCH}
  - data/fs/basic.ext2
  - bin/qemu/linux-${HOST_ARCH}/6.17/boot/kernel
  - bin/qemu/linux-${HOST_ARCH}/6.17/boot/rootfs.img
provides:
  - data/fs/basic.xfs
---

# xfs Test Image

Test image for the xfs filesystem.
