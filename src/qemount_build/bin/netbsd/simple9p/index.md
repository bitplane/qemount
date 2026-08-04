---
title: simple9p
requires:
  - sources/simple9p-v0.5.0.tar.gz
  - sources/libixp-qemount-0.2.tar.gz
provides:
  - bin/${OUTPUT_ARCH}-netbsd/simple9p
---

# simple9p

Static build of simple9p for NetBSD guests. With no explicit directory it
exports the filesystem namespace rooted at `/`.
