---
title: QEMU System Emulators
---

# QEMU System Emulators

Static builds of QEMU system emulators for each supported host platform.
These run guest operating systems that can natively mount filesystems
which the host cannot.

## Targets

- **x86_64** - Linux, BSD, DOS, Windows guests
- **aarch64** - ARM Linux/BSD guests
- **m68k** - AROS, AmigaOS, Atari TOS guests

## Host Platforms

- **x86_64-linux-musl** - Linux x86_64 (static musl)
- **x86_64-windows** - Windows x86_64
- **x86_64-macos** - macOS x86_64

## Usage

The qemount library launches the appropriate emulator based on:
1. Detected filesystem format
2. Guest OS required to mount that format
3. Host platform running the library
