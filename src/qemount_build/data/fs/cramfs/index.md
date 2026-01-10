---
format: fs/cramfs
requires:
  - docker:builder/compiler/linux/6:${HOST_ARCH}
  - data/templates/basic.tar
provides:
  - data/fs/basic.cramfs
---

# cramfs Test Image

Test image for the cramfs filesystem.
