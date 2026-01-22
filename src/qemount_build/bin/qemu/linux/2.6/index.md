---
title: Linux 2.6 Guest
env:
  BUILDER: builder/compiler/linux/2
requires:
  - docker:${BUILDER}
---

# Linux 2.6 Guest

Linux 2.6.39 kernel components. This older kernel supports legacy filesystems
that were removed from modern Linux. Only supports x86/x86_64.
