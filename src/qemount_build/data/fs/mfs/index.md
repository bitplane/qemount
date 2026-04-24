---
format: fs/mfs
build_requires:
  - bin/${HOST_ARCH}-linux-musl/mkfs.mfs
requires:
  - docker:builder/disk/qemu
  - bin/qemu/${HOST_ARCH}-linux/6.12/boot/kernel
  - bin/qemu/${HOST_ARCH}-linux/6.12/boot/rootfs.img
  - data/templates/basic.tar
provides:
  - data/fs/basic.mfs
---

# MFS Test Image

Test image for the Macintosh File System (MFS).
