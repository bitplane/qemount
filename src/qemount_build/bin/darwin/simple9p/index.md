---
title: simple9p for Darwin
build_platforms:
  x86_64-linux: {}
  aarch64-linux: {}
output_platforms:
  x86_64-darwin: {}
env:
  BUILDER: builder/compiler/puredarwin
requires:
  - docker:builder/compiler/puredarwin
  - sdk/darwin/11.3/MacOSX11.3.sdk
  - sources/simple9p-0.6.2.tar.xz
provides:
  - bin/${OUTPUT_ARCH}-darwin/simple9p
  - bin/${OUTPUT_ARCH}-darwin/stream64
---

# simple9p for Darwin

Networkless x86_64 Darwin build of simple9p. It targets Darwin 17 and serves a
connected serial stream without linking the socket transport into the binary.
The accompanying stream64 adapter carries an arbitrary byte stream through a
7-bit-clean, line-framed channel for kernel consoles which are not binary safe.
