---
format: fs/flashfs
requires:
  - docker:builder/disk/9front
build_requires:
  - guest/x86_64-9front/11957/9front.iso
  - data/templates/basic.tar
provides:
  - data/fs/basic.flashfs
---

# Plan 9 FlashFS Test Image

Two-megabyte FlashFS image populated from the standard test-data template. The
native 9front formatter creates the journal and the native file server mounts,
populates and verifies it before the image is returned.
