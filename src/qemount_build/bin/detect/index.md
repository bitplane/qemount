---
title: detect
requires:
  - docker:builder/compiler/rust
  - lib/x86_64-linux-musl/libqemount.a
  - lib/x86_64-linux-gnu/libqemount.a
  - lib/aarch64-linux-musl/libqemount.a
  - lib/aarch64-linux-gnu/libqemount.a
  - lib/x86_64-windows/qemount.lib
  - lib/x86_64-darwin/libqemount.a
  - lib/aarch64-darwin/libqemount.a
  - lib/include/qemount.h
provides:
  - bin/x86_64-linux-musl/detect
  - bin/x86_64-linux-gnu/detect
  - bin/aarch64-linux-musl/detect
  - bin/aarch64-linux-gnu/detect
  - bin/x86_64-windows/detect.exe
  - bin/x86_64-darwin/detect
  - bin/aarch64-darwin/detect
---

# detect

Simple test tool for the qemount library. Links against libqemount.a via
C FFI rather than using the Rust crate directly to validate the C ABI.

## Usage

```
detect <file>
```

Reads the first 64KB of the file and prints the detected format path
(e.g., `fs/ext4`) or exits with error if unknown.
