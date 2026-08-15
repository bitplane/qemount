---
title: simple9p for Darwin
build_platforms:
  x86_64-linux: {}
  aarch64-linux: {}
output_platforms:
  x86_64-darwin: {}
env:
  BUILDER: builder/compiler/puredarwin/17.4
requires:
  - docker:${BUILDER}
  - sources/simple9p-0.6.3.tar.xz
provides:
  - bin/${OUTPUT_ARCH}-darwin/simple9p
  - bin/${OUTPUT_ARCH}-darwin/stream64
---

# simple9p for Darwin

Networkless x86_64 Darwin build of simple9p. It targets Darwin 17 and serves a
connected serial stream without linking the socket transport into the binary.
The accompanying stream64 adapter carries an arbitrary byte stream through a
7-bit-clean, line-framed channel for kernel consoles which are not binary safe.
