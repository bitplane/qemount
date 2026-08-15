---
title: mountin library
env:
  JOBS: ${JOBS}
requires:
  - docker:builder/compiler/rust
output_platforms:
  neutral:
    provides:
      - lib/include/mountin.h
  x86_64-linux-musl:
    provides:
      - lib/x86_64-linux-musl/libmountin.a
  x86_64-linux-gnu:
    provides:
      - lib/x86_64-linux-gnu/libmountin.a
      - lib/x86_64-linux-gnu/libmountin.so
  aarch64-linux-musl:
    provides:
      - lib/aarch64-linux-musl/libmountin.a
  aarch64-linux-gnu:
    provides:
      - lib/aarch64-linux-gnu/libmountin.a
      - lib/aarch64-linux-gnu/libmountin.so
  x86_64-windows-gnu:
    provides:
      - lib/x86_64-windows-gnu/mountin.lib
      - lib/x86_64-windows-gnu/mountin.dll
  x86_64-darwin:
    provides:
      - lib/x86_64-darwin/libmountin.a
      - lib/x86_64-darwin/libmountin.dylib
  aarch64-darwin:
    provides:
      - lib/aarch64-darwin/libmountin.a
      - lib/aarch64-darwin/libmountin.dylib
  wasm32-wasi:
    provides:
      - lib/wasm32-wasi/mountin.wasm
---
