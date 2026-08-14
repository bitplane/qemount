---
title: simple9p for AROS
requires:
  - sources/simple9p-0.6.2.tar.xz
provides:
  - bin/${OUTPUT_ARCH}-aros/simple9p
---

# simple9p for AROS

Socket-free simple9p build for AROS. Its platform adapter snapshots mounted DOS
volumes and exports them beneath a synthetic `/`. It is compiled with the SDK
contained in the AROS compiler toolbox.
