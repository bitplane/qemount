---
title: simple9p
requires:
  - docker:${BUILDER}
  - sources/simple9p-0.6.3.tar.xz
provides:
  - bin/${OUTPUT_ARCH}-linux-${ENV}/simple9p
---

# simple9p

Static build of simple9p. With no explicit directory it exports the POSIX
filesystem namespace rooted at `/`.
