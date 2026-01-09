---
format: fs/nilfs2
requires:
  - docker:builder/qemu-builder:${HOST_ARCH}
  - build/data/fs/basic.ext2
  - bin/qemu/linux-x86_64/6.17/boot/kernel
  - bin/qemu/linux-x86_64/6.17/boot/rootfs.img
provides:
  - build/data/fs/basic.nilfs2
---

# nilfs2 Test Image

Test image for the nilfs2 filesystem.
