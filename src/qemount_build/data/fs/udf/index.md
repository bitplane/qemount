---
format: fs/udf
requires:
  - docker:builder/disk/qemu
  - data/templates/basic.tar
  - bin/qemu/${HOST_ARCH}-linux/6.12/boot/kernel
  - bin/qemu/${HOST_ARCH}-linux/6.12/boot/rootfs.img
provides:
  - data/fs/basic.udf
---

# udf Test Image

Test image for the udf filesystem.
