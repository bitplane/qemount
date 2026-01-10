---
format: fs/beos-bfs
requires:
  - data/templates/basic.tar
  - docker:builder/disk/haiku:${HOST_ARCH}
provides:
  - data/fs/basic.beos-bfs
---

# beos-bfs Test Image

Test image for the beos-bfs filesystem.
