---
title: simple9p
requires:
  - docker:${BUILDER}
  - sources/simple9p-qemount-0.5.tar.gz
  - sources/libixp-qemount-0.2.tar.gz
provides:
  - bin/${OUTPUT_ARCH}-linux-${ENV}/simple9p
---

# simple9p

Static build of simple9p. With no explicit directory it exports the POSIX
filesystem namespace rooted at `/`.
