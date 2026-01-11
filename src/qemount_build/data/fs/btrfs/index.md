---
format: fs/btrfs
requires:
  - docker:builder/disk/alpine
  - data/templates/basic.tar
provides:
  - data/fs/basic.btrfs
---

# btrfs Test Image

Test image for the btrfs filesystem.
