---
format: fs/hfsplus
requires:
  - docker:builder/disk/qemu:${HOST_ARCH}
  - data/fs/basic.ext2
  - bin/qemu/linux-${HOST_ARCH}/6.17/boot/kernel
  - bin/qemu/linux-${HOST_ARCH}/6.17/boot/rootfs.img
provides:
  - data/fs/basic.hfsplus
---

# hfsplus Test Image

Test image for the hfsplus filesystem.
