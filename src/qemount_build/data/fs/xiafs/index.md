---
format: fs/xiafs
build_requires:
  - bin/${BUILD_ARCH}-linux-musl/mkfs.xiafs
requires:
  - docker:builder/disk/qemu
  - bin/qemu/${BUILD_ARCH}-linux/6.12/boot/kernel
  - bin/qemu/${BUILD_ARCH}-linux/6.12/boot/rootfs.img
  - data/templates/basic.tar
provides:
  - data/fs/basic.xiafs
---

# xiafs Test Image

Test image for the xiafs filesystem.
