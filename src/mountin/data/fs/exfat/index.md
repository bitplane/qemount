---
format: fs/exfat
requires:
  - docker:builder/disk/qemu
  - data/templates/basic.tar
  - guest/${BUILD_ARCH}-linux/6.12/kernel
  - guest/${BUILD_ARCH}-linux/base/rootfs.img
provides:
  - data/fs/basic.exfat
---

# exfat Test Image

Test image for the exfat filesystem.
