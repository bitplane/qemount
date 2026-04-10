---
format: fs/xiafs
build_requires:
  - bin/${HOST_ARCH}-linux-musl/mkfs.xiafs
requires:
  - docker:builder/disk/qemu
  - data/templates/basic.tar
provides:
  - data/fs/basic.xiafs
---

# xiafs Test Image

Test image for the xiafs filesystem.
