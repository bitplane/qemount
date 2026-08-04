---
title: simple9p for AROS
requires:
  - lib/${OUTPUT_ARCH}-aros/sdk.tar.gz
  - sources/simple9p-0.6.0.tar.xz
provides:
  - bin/${OUTPUT_ARCH}-aros/simple9p
---

# simple9p for AROS

Socket-free simple9p build for AROS. Its platform adapter snapshots mounted DOS
volumes and exports them beneath a synthetic `/`.
