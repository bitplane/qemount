---
format: fs/udf
requires:
  - docker:builder/disk/qemu
  - data/templates/basic.tar
  - guest/${MOUNTIN_BUILD_ARCH}-linux/6.12/kernel
  - guest/${MOUNTIN_BUILD_ARCH}-linux/base/rootfs.img
provides:
  - data/fs/basic.udf-optical
---

# Optical UDF Test Image

UDF 1.02 test image with 2048-byte sectors and a physical partition map,
populated from the standard test-data template. This complements the 512-byte
hard-disk-style `basic.udf` fixture.
