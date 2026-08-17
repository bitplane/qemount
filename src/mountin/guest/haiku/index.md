---
title: Haiku guest components
build_platforms:
  x86_64-linux: {}
output_platforms:
  x86_64-haiku: {}
env:
  BUILDER: builder/compiler/haiku/r1-beta6-hrev59919-1
  HAIKU_IMAGE_SIZE: "7"
  HAIKU_REVISION: hrev59919+1
  JOBS: "1"
requires:
  - docker:${BUILDER}
---

# Haiku guest components
