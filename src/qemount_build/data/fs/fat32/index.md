---
format: fs/fat32
requires:
  - docker:builder/disk/alpine
  - data/templates/basic.tar
provides:
  - data/fs/basic.fat32
---

# fat32 Test Image

Test image for the fat32 filesystem.
