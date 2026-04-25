---
title: mkfs.bfs
requires:
  - docker:builder/compiler/linux/6
provides:
  - bin/${HOST_ARCH}-linux-musl/mkfs.bfs
---

# mkfs.bfs

Minimal SCO BFS filesystem image creator. Creates flat BFS images for testing,
optionally populated from a directory tree via `-d`.
