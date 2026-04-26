---
title: mkfs.bfs
env:
  CARGO_HOME: /host/build/cache/cargo
  CARGO_TARGET_DIR: /host/build/cache/cargo-target
  ZIG_GLOBAL_CACHE_DIR: /host/build/cache/zig
build_requires:
  - sources/mkfs-bfs-0.1.0.tar.gz
requires:
  - docker:builder/compiler/rust
provides:
  - bin/${HOST_ARCH}-linux-musl/mkfs.bfs
---

# mkfs.bfs

Static musl build of [bitplane/mkfs-bfs](https://github.com/bitplane/mkfs-bfs)
(Rust). Creates SCO BFS (Boot File System) images.
