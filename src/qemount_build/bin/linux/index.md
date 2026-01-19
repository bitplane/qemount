---
title: Linux binaries
env:
  BUILDER: builder/compiler/linux/6:${HOST_ARCH}
  ENV: musl
requires:
  - docker:${BUILDER}
---

# Linux binaries

Binaries built for the Linux operating system. These might run on a host or
inside a guest, but they're ELF binaries and are built on the linux 6.x
builder.
