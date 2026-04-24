---
format: fs/ext
build_requires:
  - bin/${HOST_ARCH}-linux-musl/mkfs.ext
requires:
  - docker:builder/disk/qemu
  - bin/qemu/${HOST_ARCH}-linux/6.12/boot/kernel
  - bin/qemu/${HOST_ARCH}-linux/6.12/boot/rootfs.img
  - data/templates/basic.tar
provides:
  - data/fs/basic.ext
---

# ext Test Image

Test image for the original extended filesystem (ext).
