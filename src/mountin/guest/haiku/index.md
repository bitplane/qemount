---
title: Haiku guest components
build_platforms:
  x86_64-linux: {}
  aarch64-linux: {}
output_platforms:
  x86_64-haiku:
    env:
      MOUNTIN_HAIKU_ARCH: x86_64
  aarch64-haiku:
    env:
      MOUNTIN_HAIKU_ARCH: arm64
env:
  MOUNTIN_BUILDER: builder/compiler/haiku/r1-beta6-hrev59919-1/${MOUNTIN_TARGET_ARCH}
  MOUNTIN_HAIKU_IMAGE_SIZE: "7"
  MOUNTIN_HAIKU_REVISION: hrev59919+1
execution_env:
  MOUNTIN_BUILD_JOBS: "1"
requires:
  - docker:${MOUNTIN_BUILDER}
---

# Haiku guest components
