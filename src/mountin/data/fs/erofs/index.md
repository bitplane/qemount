---
format: fs/erofs
requires:
  - docker:builder/disk/alpine
  - data/templates/basic.tar
provides:
  - data/fs/basic.erofs
---

# erofs Test Image

Test image for the erofs filesystem.
