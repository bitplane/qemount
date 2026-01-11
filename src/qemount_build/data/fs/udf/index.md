---
format: fs/udf
requires:
  - docker:builder/disk/qemu
  - data/templates/basic.tar
  - bin/qemu/linux-${HOST_ARCH}/6.17/boot/kernel
  - bin/qemu/linux-${HOST_ARCH}/6.17/boot/rootfs.img
provides:
  - data/fs/basic.udf
---

# udf Test Image

Test image for the udf filesystem.
