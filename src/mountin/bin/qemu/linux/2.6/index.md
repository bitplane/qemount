---
title: Linux 2.6 Guest
-output_platforms: true
output_platforms:
  x86_64-linux: {}
-build_platforms: true
build_platforms:
  x86_64-linux: {}
  aarch64-linux: {}
env:
  MOUNTIN_BUILDER: builder/compiler/linux/2
requires:
  - docker:${MOUNTIN_BUILDER}
---

# Linux 2.6 Guest

Linux 2.6.39 kernel components. This older kernel supports legacy filesystems
that were removed from modern Linux. Only supports x86/x86_64.
