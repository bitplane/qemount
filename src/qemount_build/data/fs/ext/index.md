---
format: fs/ext
requires:
  - docker:builder/disk/qemu
  - data/templates/basic.tar
  - bin/${HOST_ARCH}-linux-musl/mkfs.ext
provides:
  - data/fs/basic.ext
---

# ext Test Image

Test image for the original extended filesystem (ext).
