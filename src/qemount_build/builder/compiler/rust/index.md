---
title: Rust Cross-Compiler
provides:
  - docker:builder/compiler/rust
---

# Rust Cross-Compiler

Rust toolchain with cargo-zigbuild for cross-compiling to multiple platforms
from a single build environment.

## Targets

- Linux x86_64/aarch64 (musl and glibc)
- Windows x86_64
- macOS x86_64/aarch64
- WASM (wasi)
