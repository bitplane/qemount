---
format: fs/beos-bfs
requires:
  - build/data/templates/basic.tar
  - docker:builder/compiler/haiku:${HOST_ARCH}
provides:
  - build/data/fs/basic.beos-bfs
---

# beos-bfs Test Image

Test image for the beos-bfs filesystem.
