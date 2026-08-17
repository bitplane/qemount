---
format: fs/xiafs
build_requires:
  - bin/${BUILD_ARCH}-linux-musl/mkfs.xiafs
requires:
  - docker:builder/disk/qemu
  - guest/${BUILD_ARCH}-linux/6.12/kernel
  - guest/${BUILD_ARCH}-linux/base/rootfs.img
  - data/templates/basic.tar
provides:
  - data/fs/basic.xiafs
---

# xiafs Test Image

Test image for the xiafs filesystem.
