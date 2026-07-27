---
title: simple9p for AROS
requires:
  - lib/${ARCH}-aros/sdk.tar.gz
  - sources/simple9p-qemount.tar.gz
  - sources/libixp-simple9p.tar.gz
provides:
  - bin/${ARCH}-aros/simple9p
---

# simple9p for AROS

Socket-free simple9p build for AROS. It accepts an already-connected stream
path and uses no AROS-specific source code.
