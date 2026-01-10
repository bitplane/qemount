---
format: fs/hfsplus
requires:
  - docker:builder/qemu-builder:${HOST_ARCH}
  - data/fs/basic.ext2
  - bin/qemu/linux-x86_64/6.17/boot/kernel
  - bin/qemu/linux-x86_64/6.17/boot/rootfs.img
provides:
  - data/fs/basic.hfsplus
---

# hfsplus Test Image

Test image for the hfsplus filesystem.
