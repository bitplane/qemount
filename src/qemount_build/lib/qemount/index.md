---
title: qemount library
env:
  JOBS: ${JOBS}
  CARGO_HOME: /host/build/cache/cargo
  CARGO_TARGET_DIR: /host/build/cache/cargo-target/${BUILD_PLATFORM}
  ZIG_GLOBAL_CACHE_DIR: /host/build/cache/zig/${BUILD_PLATFORM}
requires:
  - docker:builder/compiler/rust
output_platforms:
  neutral:
    provides:
      - lib/include/qemount.h
  x86_64-linux-musl:
    provides:
      - lib/x86_64-linux-musl/libqemount.a
  x86_64-linux-gnu:
    provides:
      - lib/x86_64-linux-gnu/libqemount.a
      - lib/x86_64-linux-gnu/libqemount.so
  aarch64-linux-musl:
    provides:
      - lib/aarch64-linux-musl/libqemount.a
  aarch64-linux-gnu:
    provides:
      - lib/aarch64-linux-gnu/libqemount.a
      - lib/aarch64-linux-gnu/libqemount.so
  x86_64-windows-gnu:
    provides:
      - lib/x86_64-windows-gnu/qemount.lib
      - lib/x86_64-windows-gnu/qemount.dll
  x86_64-darwin:
    provides:
      - lib/x86_64-darwin/libqemount.a
      - lib/x86_64-darwin/libqemount.dylib
  aarch64-darwin:
    provides:
      - lib/aarch64-darwin/libqemount.a
      - lib/aarch64-darwin/libqemount.dylib
  wasm32-wasi:
    provides:
      - lib/wasm32-wasi/qemount.wasm
---
