---
format: fs/sysv
requires:
  - build/data/fs/basic.ext2
  - bin/qemu/linux-x86_64/2.6/boot/kernel
  - bin/qemu/linux-x86_64/2.6/boot/rootfs.img
provides:
  - build/data/fs/basic.sysv
---

# sysv Test Image

Test image for the sysv filesystem.
