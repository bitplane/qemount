---
title: 9d
requires:
  - sources/9d-0.7.0.tar.xz
provides:
  - bin/${OUTPUT_ARCH}-netbsd/9d
---

# 9d

Static build of 9d for NetBSD guests. With no explicit directory it
exports the filesystem namespace rooted at `/`.
