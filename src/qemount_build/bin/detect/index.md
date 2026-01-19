---
title: detect
requires:
  - docker:builder/compiler/rust
  - lib/linux-x86_64-musl/libqemount.a
  - lib/linux-x86_64-gnu/libqemount.a
  - lib/linux-aarch64-musl/libqemount.a
  - lib/linux-aarch64-gnu/libqemount.a
  - lib/windows-x86_64/qemount.lib
  - lib/darwin-x86_64/libqemount.a
  - lib/darwin-aarch64/libqemount.a
  - lib/include/qemount.h
provides:
  - bin/linux-x86_64-musl/detect
  - bin/linux-x86_64-gnu/detect
  - bin/linux-aarch64-musl/detect
  - bin/linux-aarch64-gnu/detect
  - bin/windows-x86_64/detect.exe
  - bin/darwin-x86_64/detect
  - bin/darwin-aarch64/detect
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
