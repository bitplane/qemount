---
format: fs/cramfs
requires:
  - docker:builder/compiler/linux/6:${HOST_ARCH}
  - build/data/templates/basic.tar
provides:
  - build/data/fs/basic.cramfs
---

# cramfs Test Image

Test image for the cramfs filesystem.
