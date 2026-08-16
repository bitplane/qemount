---
title: detect
requires:
  - docker:builder/compiler/rust
  - lib/include/mountin.h
output_platforms:
  x86_64-linux-musl:
    requires:
      - lib/x86_64-linux-musl/libmountin.a
    provides:
      - bin/x86_64-linux-musl/detect
  x86_64-linux-gnu:
    requires:
      - lib/x86_64-linux-gnu/libmountin.a
    provides:
      - bin/x86_64-linux-gnu/detect
  aarch64-linux-musl:
    requires:
      - lib/aarch64-linux-musl/libmountin.a
    provides:
      - bin/aarch64-linux-musl/detect
  aarch64-linux-gnu:
    requires:
      - lib/aarch64-linux-gnu/libmountin.a
    provides:
      - bin/aarch64-linux-gnu/detect
  x86_64-windows-gnu:
    requires:
      - lib/x86_64-windows-gnu/mountin.lib
    provides:
      - bin/x86_64-windows-gnu/detect.exe
  x86_64-darwin:
    requires:
      - lib/x86_64-darwin/libmountin.a
    provides:
      - bin/x86_64-darwin/detect
  aarch64-darwin:
    requires:
      - lib/aarch64-darwin/libmountin.a
    provides:
      - bin/aarch64-darwin/detect
---

# detect

Simple test tool for the mountin library. Links against libmountin.a via
C FFI rather than using the Rust crate directly to validate the C ABI.

## Usage

```
detect <format.bin> <file>...
```

Recursively detects format trees for each file, descending into containers
(compressed streams, disk images, partition tables). Prints detected formats
with indentation showing nesting depth. Exits 0 if any formats detected, 1 otherwise.
