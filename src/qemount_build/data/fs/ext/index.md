---
format: fs/ext
build_requires:
  - bin/${HOST_ARCH}-linux-musl/mkfs.ext
requires:
  - docker:builder/disk/qemu
  - data/templates/basic.tar
provides:
  - data/fs/basic.ext
---

# ext Test Image

Test image for the original extended filesystem (ext).
