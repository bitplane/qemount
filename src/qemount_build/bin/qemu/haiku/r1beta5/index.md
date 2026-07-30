---
title: Haiku R1 Beta 5 Guest
env:
  ARCH: x86_64
  BUILDER: builder/compiler/haiku
  HAIKU_REVISION: hrev57937+137
requires:
  - docker:${BUILDER}
---

# Haiku R1 Beta 5 Guest

Stock Haiku R1 Beta 5 minimum image used to establish the guest integration
before maintaining any qemount-specific Haiku source branch.
