---
title: detect
env:
  ZIG_GLOBAL_CACHE_DIR: /host/build/cache/zig/${BUILD_PLATFORM}
requires:
  - docker:builder/compiler/rust
  - lib/include/qemount.h
output_platforms:
  x86_64-linux-musl:
    requires:
      - lib/x86_64-linux-musl/libqemount.a
    provides:
      - bin/x86_64-linux-musl/detect
  x86_64-linux-gnu:
    requires:
      - lib/x86_64-linux-gnu/libqemount.a
    provides:
      - bin/x86_64-linux-gnu/detect
  aarch64-linux-musl:
    requires:
      - lib/aarch64-linux-musl/libqemount.a
    provides:
      - bin/aarch64-linux-musl/detect
  aarch64-linux-gnu:
    requires:
      - lib/aarch64-linux-gnu/libqemount.a
    provides:
      - bin/aarch64-linux-gnu/detect
  x86_64-windows-gnu:
    requires:
      - lib/x86_64-windows-gnu/qemount.lib
    provides:
      - bin/x86_64-windows-gnu/detect.exe
  x86_64-darwin:
    requires:
      - lib/x86_64-darwin/libqemount.a
    provides:
      - bin/x86_64-darwin/detect
  aarch64-darwin:
    requires:
      - lib/aarch64-darwin/libqemount.a
    provides:
      - bin/aarch64-darwin/detect
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
