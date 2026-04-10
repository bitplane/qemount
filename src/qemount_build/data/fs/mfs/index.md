---
format: fs/mfs
build_requires:
  - bin/${HOST_ARCH}-linux-musl/mkfs.mfs
requires:
  - docker:builder/disk/qemu
  - data/templates/basic.tar
provides:
  - data/fs/basic.mfs
---

# MFS Test Image

Test image for the Macintosh File System (MFS).
