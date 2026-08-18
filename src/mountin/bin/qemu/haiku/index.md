---
title: Haiku QEMU Guests
build_platforms:
  x86_64-linux: {}
output_platforms:
  x86_64-haiku: {}
env:
  MOUNTIN_BUILDER: builder/compiler/haiku/r1-beta6-hrev59919-1
  MOUNTIN_HAIKU_IMAGE_SIZE: "7"
  MOUNTIN_HAIKU_REVISION: hrev59919+1
execution_env:
  MOUNTIN_BUILD_JOBS: "1"
requires:
  - docker:${MOUNTIN_BUILDER}
---

# Haiku QEMU Guests

Haiku-based virtual machines for QEMU.
