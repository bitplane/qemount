---
title: simple9p for AROS
requires:
  - lib/${ARCH}-aros/sdk.tar.gz
  - sources/simple9p-qemount-0.3.tar.gz
  - sources/libixp-qemount-0.2.tar.gz
provides:
  - bin/${ARCH}-aros/simple9p
---

# simple9p for AROS

Socket-free simple9p build for AROS. Its platform adapter snapshots mounted DOS
volumes and exports them beneath a synthetic `/`.
