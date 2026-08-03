---
title: PureDarwin qemount Guest
build_platforms:
  x86_64-linux: {}
  aarch64-linux: {}
output_platforms:
  x86_64-darwin: {}
env:
  BUILDER: builder/compiler/puredarwin
requires:
  - docker:${BUILDER}
---

# PureDarwin qemount Guest

Experimental x86_64 PureDarwin guest. Darwin 17.4 XNU builds from its pinned
Apple source on Linux, while the project's 17.4 image provides the proven boot
chain, driver set and initial userland substrate.
