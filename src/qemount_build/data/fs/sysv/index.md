---
format: fs/sysv
kernel: "2.6"
requires:
  - docker:builder/disk/qemu
  - data/templates/basic.tar
  - bin/qemu/${HOST_ARCH}-linux/2.6/boot/kernel
  - bin/qemu/${HOST_ARCH}-linux/2.6/boot/rootfs.img
provides:
  - data/fs/basic.sysv
---

# sysv Test Image

Test image for the sysv (System V) filesystem.
