---
format: fs/sco-bfs
build_requires:
  - bin/${HOST_ARCH}-linux-musl/mkfs.bfs
requires:
  - docker:builder/disk/alpine
  - data/templates/basic.tar
provides:
  - data/fs/basic.sco-bfs
---

# sco-bfs Test Image

Test image for the sco-bfs filesystem.
