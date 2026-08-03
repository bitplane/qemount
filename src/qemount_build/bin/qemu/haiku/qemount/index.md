---
title: Haiku qemount Guest
build_platforms:
  x86_64-linux: {}
output_platforms:
  x86_64-haiku: {}
env:
  BUILDER: builder/compiler/haiku
  HAIKU_IMAGE_SIZE: "7"
  HAIKU_REVISION: hrev59919+1
  JOBS: "1"
requires:
  - docker:${BUILDER}
---

# Haiku qemount Guest

Minimal x86_64 Haiku guest built from the qemount integration branch.
