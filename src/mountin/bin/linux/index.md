---
title: Linux binaries
build_platforms:
  x86_64-linux: {}
  aarch64-linux: {}
output_platforms:
  x86_64-linux-musl: {}
  aarch64-linux-musl: {}
env:
  MOUNTIN_BUILDER: builder/compiler/linux/6/${MOUNTIN_TARGET_ARCH}
  MOUNTIN_LIBC: musl
---

# Linux binaries

Binaries built for the Linux operating system. These might run on a host or
inside a guest, but they're ELF binaries.

C-built children use the target-specific `${MOUNTIN_BUILDER}` toolbox; the
same interface is used for native and cross builds. Rust-built children use
`builder/compiler/rust`. Each child declares its own builder image in
`requires:`.
