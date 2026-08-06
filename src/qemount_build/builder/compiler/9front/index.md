---
title: 9front bootstrap environment
build_platforms:
  x86_64-linux: {}
provides:
  - docker:builder/compiler/9front
---

# 9front bootstrap environment

Linux-hosted orchestration tools for running 9front's native, self-hosted
compiler inside QEMU. The official stage-0 image and pinned source tree remain
separate declared inputs of the guest build.
