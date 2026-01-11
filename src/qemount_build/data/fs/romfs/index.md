---
format: fs/romfs
requires:
  - docker:builder/disk/debian
  - data/templates/basic.tar
provides:
  - data/fs/basic.romfs
---

# romfs Test Image

Test image for the romfs filesystem.
