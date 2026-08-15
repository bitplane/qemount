---
format: fs/cramfs
requires:
  - docker:builder/disk/alpine
  - data/templates/basic.tar
provides:
  - data/fs/basic.cramfs
---

# cramfs Test Image

Test image for the cramfs filesystem.
