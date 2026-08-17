---
format: fs/udf
requires:
  - docker:builder/disk/qemu
  - data/templates/basic.tar
  - guest/${BUILD_ARCH}-linux/6.12/kernel
  - guest/${BUILD_ARCH}-linux/base/rootfs.img
provides:
  - data/fs/basic.udf-optical-efe
---

# Extended File Entry UDF Test Image

UDF 2.01 test image with 2048-byte sectors, Extended File Entries and a
physical partition map, populated from the standard test-data template.
