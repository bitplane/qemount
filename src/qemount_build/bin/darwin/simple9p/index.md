---
title: simple9p for Darwin
env:
  ARCH: x86_64
  BUILDER: builder/compiler/puredarwin
requires:
  - docker:builder/compiler/puredarwin
  - sources/MacOSX11.3.sdk.tar.xz
  - sources/simple9p-qemount-0.5.tar.gz
  - sources/libixp-qemount-0.2.tar.gz
provides:
  - bin/${ARCH}-darwin/simple9p
  - bin/${ARCH}-darwin/stream64
---

# simple9p for Darwin

Networkless x86_64 Darwin build of simple9p. It targets Darwin 17 and serves a
connected serial stream without linking the socket transport into the binary.
The accompanying stream64 adapter carries an arbitrary byte stream through a
7-bit-clean, line-framed channel for kernel consoles which are not binary safe.
