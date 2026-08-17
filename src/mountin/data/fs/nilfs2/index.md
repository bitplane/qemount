---
format: fs/nilfs2
requires:
  - docker:builder/disk/qemu
  - data/templates/basic.tar
  - guest/${BUILD_ARCH}-linux/6.12/kernel
  - guest/${BUILD_ARCH}-linux/base/rootfs.img
provides:
  - data/fs/basic.nilfs2
---

# nilfs2 Test Image

Test image for the nilfs2 filesystem.
