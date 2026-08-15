---
format: fs/ext4
requires:
  - docker:builder/disk/alpine
  - data/templates/basic.tar
provides:
  - data/fs/basic.ext4
---

# ext4 Test Image

Test image for the ext4 filesystem.
