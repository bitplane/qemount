---
format: fs/gemdos
build_requires:
  - bin/${HOST_ARCH}-linux-musl/mkfs.gemdos
requires:
  - docker:builder/disk/qemu
  - data/templates/basic.tar
provides:
  - data/fs/basic.gemdos
---

# GEMDOS Test Image

Test image for the GEMDOS (Atari TOS) filesystem.
