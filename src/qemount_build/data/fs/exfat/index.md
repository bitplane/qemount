---
format: fs/exfat
requires:
  - docker:builder/qemu-builder:${HOST_ARCH}
  - data/fs/basic.ext2
  - bin/qemu/linux-${HOST_ARCH}/6.17/boot/kernel
  - bin/qemu/linux-${HOST_ARCH}/6.17/boot/rootfs.img
provides:
  - data/fs/basic.exfat
---

# exfat Test Image

Test image for the exfat filesystem.
