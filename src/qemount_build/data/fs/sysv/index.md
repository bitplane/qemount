---
format: fs/sysv
build_requires:
  - bin/${HOST_ARCH}-linux-musl/mkfs.sysv
requires:
  - docker:builder/disk/alpine
  - data/templates/basic.tar
provides:
  - data/fs/basic.sysv
---

# sysv Test Image

Test image for the sysv (System V) filesystem.
