---
title: QEMU Cross-Compiler
build_platforms:
  x86_64-linux: {}
  aarch64-linux: {}
requires:
  - sources/qemu-10.2.0.tar.xz
  - sources/glib-2.82.4.tar.xz
  - sources/pixman-0.44.2.tar.gz
  - sources/libffi-3.4.6.tar.gz
  - sources/libiconv-1.17.tar.gz
  - sources/MacOSX11.3.sdk.tar.xz
output_platforms:
  x86_64-linux-musl:
    provides:
      - bin/qemu-system/x86_64-linux-musl/qemu-system-x86_64
      - bin/qemu-system/x86_64-linux-musl/qemu-system-aarch64
      - bin/qemu-system/x86_64-linux-musl/qemu-system-m68k
  aarch64-linux-musl:
    provides:
      - bin/qemu-system/aarch64-linux-musl/qemu-system-x86_64
      - bin/qemu-system/aarch64-linux-musl/qemu-system-aarch64
      - bin/qemu-system/aarch64-linux-musl/qemu-system-m68k
  x86_64-windows-gnu:
    provides:
      - bin/qemu-system/x86_64-windows-gnu/qemu-system-x86_64.exe
      - bin/qemu-system/x86_64-windows-gnu/qemu-system-aarch64.exe
      - bin/qemu-system/x86_64-windows-gnu/qemu-system-m68k.exe
  x86_64-darwin:
    provides:
      - bin/qemu-system/x86_64-darwin/qemu-system-x86_64
      - bin/qemu-system/x86_64-darwin/qemu-system-aarch64
      - bin/qemu-system/x86_64-darwin/qemu-system-m68k
---

# QEMU Cross-Compiler

Builds static QEMU system emulators for all host platforms using zig
as a cross-compiler. Dependencies (glib, pixman) are built from source
for each target.

## Targets

QEMU emulator targets:
- x86_64-softmmu
- aarch64-softmmu
- m68k-softmmu

## Host Platforms

- x86_64-linux-musl
- x86_64-windows-gnu (MinGW)
- x86_64-darwin
