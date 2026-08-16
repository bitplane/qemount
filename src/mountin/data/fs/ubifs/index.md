---
format: fs/ubifs
requires:
  - docker:builder/disk/alpine
  - data/templates/basic.tar
provides:
  - data/fs/basic.ubifs
---

# ubifs Test Image

Test image for the ubifs filesystem.
