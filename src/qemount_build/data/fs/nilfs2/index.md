---
format: fs/nilfs2
requires:
  - docker:builder/disk/qemu:${HOST_ARCH}
  - data/fs/basic.ext2
  - bin/qemu/linux-${HOST_ARCH}/6.17/boot/kernel
  - bin/qemu/linux-${HOST_ARCH}/6.17/boot/rootfs.img
provides:
  - data/fs/basic.nilfs2
---

# nilfs2 Test Image

Test image for the nilfs2 filesystem.
