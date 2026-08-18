---
title: 9d
requires:
  - docker:${MOUNTIN_BUILDER}
  - sources/9d-0.7.1.tar.xz
provides:
  - bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/9d
---

# 9d

Static build of 9d. With no explicit directory it exports the POSIX
filesystem namespace rooted at `/`.
