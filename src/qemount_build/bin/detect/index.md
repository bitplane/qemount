---
title: detect
env:
  ZIG_GLOBAL_CACHE_DIR: /host/build/cache/zig
requires:
  - docker:builder/compiler/rust
  - lib/include/qemount.h
provides:
  bin/x86_64-linux-musl/detect:
    requires:
      - lib/x86_64-linux-musl/libqemount.a
  bin/x86_64-linux-gnu/detect:
    requires:
      - lib/x86_64-linux-gnu/libqemount.a
  bin/aarch64-linux-musl/detect:
    requires:
      - lib/aarch64-linux-musl/libqemount.a
  bin/aarch64-linux-gnu/detect:
    requires:
      - lib/aarch64-linux-gnu/libqemount.a
  bin/x86_64-windows/detect.exe:
    requires:
      - lib/x86_64-windows/qemount.lib
  bin/x86_64-darwin/detect:
    requires:
      - lib/x86_64-darwin/libqemount.a
  bin/aarch64-darwin/detect:
    requires:
      - lib/aarch64-darwin/libqemount.a
---

# detect

Simple test tool for the qemount library. Links against libqemount.a via
C FFI rather than using the Rust crate directly to validate the C ABI.

## Usage

```
detect <file>...
```

Recursively detects format trees for each file, descending into containers
(compressed streams, disk images, partition tables). Prints detected formats
with indentation showing nesting depth. Exits 0 if any formats detected, 1 otherwise.
