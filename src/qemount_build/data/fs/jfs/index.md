---
format: fs/jfs
requires:
  - docker:builder/qemu-builder:${HOST_ARCH}
  - data/fs/basic.ext2
  - bin/qemu/linux-x86_64/6.17/boot/kernel
  - bin/qemu/linux-x86_64/6.17/boot/rootfs.img
provides:
  - data/fs/basic.jfs
---

# jfs Test Image

Test image for the jfs filesystem.
