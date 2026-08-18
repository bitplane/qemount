---
title: mkfs.bfs
build_requires:
  - sources/mkfs-bfs-0.1.0.tar.gz
requires:
  - docker:builder/compiler/rust
provides:
  - bin/${MOUNTIN_TARGET_ARCH}-linux-musl/mkfs.bfs
---

# mkfs.bfs

Static musl build of [bitplane/mkfs-bfs](https://github.com/bitplane/mkfs-bfs)
(Rust). Creates SCO BFS (Boot File System) images.
