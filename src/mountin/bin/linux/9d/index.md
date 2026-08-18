---
title: 9d
requires:
  - docker:${BUILDER}
  - sources/9d-0.7.1.tar.xz
provides:
  - bin/${TARGET_ARCH}-linux-${ENV}/9d
---

# 9d

Static build of 9d. With no explicit directory it exports the POSIX
filesystem namespace rooted at `/`.
