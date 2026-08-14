---
title: Haiku QEMU Guests
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

# Haiku QEMU Guests

Haiku-based virtual machines for QEMU.
