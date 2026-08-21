---
title: Haiku Disk Builder
build_platforms:
  x86_64-linux: {}
  aarch64-linux: {}
env:
  MOUNTIN_TARGET_ARCH: x86_64
requires:
  - docker:builder/compiler/haiku/r1-beta6-hrev59919-1/x86_64
provides:
  - docker:builder/disk/haiku
---

# Haiku Disk Builder

Haiku-based image with bfs_shell for creating BeOS BFS disk images.
