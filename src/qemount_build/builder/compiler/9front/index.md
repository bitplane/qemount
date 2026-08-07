---
title: 9front bootstrap environment
build_platforms:
  x86_64-linux: {}
  aarch64-linux: {}
provides:
  - docker:builder/compiler/9front
---

# 9front bootstrap environment

Linux-hosted orchestration tools for running 9front's native, self-hosted
compiler inside QEMU. The amd64 stage-0 environment can build both amd64 and
ARM64 9front outputs. The official stage-0 image and pinned source tree remain
separate declared inputs of the guest build.
