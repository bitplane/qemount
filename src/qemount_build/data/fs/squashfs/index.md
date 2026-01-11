---
format: fs/squashfs
requires:
  - docker:builder/disk/alpine
  - data/templates/basic.tar
provides:
  - data/fs/basic.squashfs
---

# squashfs Test Image

Test image for the squashfs filesystem.
