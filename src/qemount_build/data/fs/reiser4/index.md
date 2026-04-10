---
format: fs/reiser4
build_requires:
  - bin/${HOST_ARCH}-linux-gnu/mkfs.reiser4
  - bin/${HOST_ARCH}-linux-gnu/reiser4-busy
requires:
  - docker:builder/disk/qemu
  - data/templates/basic.tar
provides:
  - data/fs/basic.reiser4
---

# Reiser4 Test Image

Test image for the Reiser4 filesystem.
