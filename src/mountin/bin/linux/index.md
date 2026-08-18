---
title: Linux binaries
build_platforms:
  x86_64-linux: {}
  aarch64-linux: {}
output_platforms:
  x86_64-linux-musl:
    build_platforms:
      x86_64-linux: {}
  aarch64-linux-musl:
    build_platforms:
      aarch64-linux: {}
env:
  MOUNTIN_BUILDER: builder/compiler/linux/6
  MOUNTIN_LIBC: musl
---

# Linux binaries

Binaries built for the Linux operating system. These might run on a host or
inside a guest, but they're ELF binaries.

C-built children typically use the `${MOUNTIN_BUILDER}` (linux 6.x) image; Rust-built
children use `builder/compiler/rust`. Each child declares its own builder
image in `requires:`.
