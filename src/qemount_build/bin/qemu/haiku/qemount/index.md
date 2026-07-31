---
title: Haiku qemount Guest
env:
  ARCH: x86_64
  BUILDER: builder/compiler/haiku
  HAIKU_IMAGE_SIZE: "128"
  HAIKU_REVISION: hrev59919+1
  JOBS: "1"
requires:
  - docker:${BUILDER}
---

# Haiku qemount Guest

Minimal x86_64 Haiku guest built from the qemount integration branch.
