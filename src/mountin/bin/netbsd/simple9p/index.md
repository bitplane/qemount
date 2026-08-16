---
title: simple9p
requires:
  - sources/simple9p-0.6.4.tar.xz
provides:
  - bin/${OUTPUT_ARCH}-netbsd/simple9p
---

# simple9p

Static build of simple9p for NetBSD guests. With no explicit directory it
exports the filesystem namespace rooted at `/`.
