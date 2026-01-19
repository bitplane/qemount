---
title: qemount library
requires:
  - docker:builder/compiler/rust
  - lib/format.bin
provides:
  - lib/x86_64-linux-musl/libqemount.a
  - lib/x86_64-linux-gnu/libqemount.a
  - lib/x86_64-linux-gnu/libqemount.so
  - lib/aarch64-linux-musl/libqemount.a
  - lib/aarch64-linux-gnu/libqemount.a
  - lib/aarch64-linux-gnu/libqemount.so
  - lib/x86_64-windows/qemount.lib
  - lib/x86_64-windows/qemount.dll
  - lib/x86_64-darwin/libqemount.a
  - lib/x86_64-darwin/libqemount.dylib
  - lib/aarch64-darwin/libqemount.a
  - lib/aarch64-darwin/libqemount.dylib
  - lib/wasm32/qemount.wasm
  - lib/include/qemount.h
---
