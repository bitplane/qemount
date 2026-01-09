---
format: fs/exfat
requires:
  - docker:builder/qemu-builder:${HOST_ARCH}
  - build/data/fs/basic.ext2
  - bin/qemu/linux-x86_64/6.17/boot/kernel
  - bin/qemu/linux-x86_64/6.17/boot/rootfs.img
provides:
  - build/data/fs/basic.exfat
---

# exfat Test Image

Test image for the exfat filesystem.
