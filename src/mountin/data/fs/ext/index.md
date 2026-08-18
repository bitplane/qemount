---
format: fs/ext
build_requires:
  - bin/${MOUNTIN_BUILD_ARCH}-linux-musl/mkfs.ext
requires:
  - docker:builder/disk/qemu
  - guest/${MOUNTIN_BUILD_ARCH}-linux/6.12/kernel
  - guest/${MOUNTIN_BUILD_ARCH}-linux/base/rootfs.img
  - data/templates/basic.tar
provides:
  - data/fs/basic.ext
---

# ext Test Image

Test image for the original extended filesystem (ext).
