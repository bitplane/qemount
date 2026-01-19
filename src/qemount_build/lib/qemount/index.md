---
title: qemount library
requires:
  - docker:builder/compiler/rust
  - lib/format.bin
provides:
  - lib/linux-x86_64-musl/libqemount.a
  - lib/linux-x86_64-gnu/libqemount.a
  - lib/linux-x86_64-gnu/libqemount.so
  - lib/linux-aarch64-musl/libqemount.a
  - lib/linux-aarch64-gnu/libqemount.a
  - lib/linux-aarch64-gnu/libqemount.so
  - lib/windows-x86_64/qemount.lib
  - lib/windows-x86_64/qemount.dll
  - lib/darwin-x86_64/libqemount.a
  - lib/darwin-x86_64/libqemount.dylib
  - lib/darwin-aarch64/libqemount.a
  - lib/darwin-aarch64/libqemount.dylib
  - lib/wasm/qemount.wasm
  - lib/include/qemount.h
---
