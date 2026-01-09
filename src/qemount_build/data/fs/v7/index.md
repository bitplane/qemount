---
format: fs/v7
requires:
  - docker:builder/compiler/netbsd/10.0:${HOST_ARCH}
  - build/data/templates/basic.tar
provides:
  - build/data/fs/basic.v7
---

# v7 Test Image

Test image for the v7 filesystem.
