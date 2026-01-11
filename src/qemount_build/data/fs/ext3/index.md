---
format: fs/ext3
requires:
  - docker:builder/disk/alpine
  - data/templates/basic.tar
provides:
  - data/fs/basic.ext3
---

# ext3 Test Image

Test image for the ext3 filesystem.
