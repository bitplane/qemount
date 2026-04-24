---
format: fs/nilfs2
requires:
  - docker:builder/disk/qemu
  - data/templates/basic.tar
  - bin/qemu/${HOST_ARCH}-linux/6.12/boot/kernel
  - bin/qemu/${HOST_ARCH}-linux/6.12/boot/rootfs.img
provides:
  - data/fs/basic.nilfs2
---

# nilfs2 Test Image

Test image for the nilfs2 filesystem.
