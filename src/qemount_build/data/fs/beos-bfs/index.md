---
format: fs/beos-bfs
requires:
  - data/templates/basic.tar
  - docker:builder/compiler/haiku:${HOST_ARCH}
provides:
  - data/fs/basic.beos-bfs
---

# beos-bfs Test Image

Test image for the beos-bfs filesystem.
