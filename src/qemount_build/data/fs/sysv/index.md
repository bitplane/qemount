---
format: fs/sysv
requires:
  - data/fs/basic.ext2
  - bin/qemu/linux-${HOST_ARCH}/2.6/boot/kernel
  - bin/qemu/linux-${HOST_ARCH}/2.6/boot/rootfs.img
provides:
  - data/fs/basic.sysv
---

# sysv Test Image

Test image for the sysv filesystem.
