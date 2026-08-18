---
title: socat
requires:
  - docker:${MOUNTIN_BUILDER}
  - sources/socat-1.7.4.4.tar.gz
provides:
  - bin/${MOUNTIN_TARGET_ARCH}-linux-${MOUNTIN_LIBC}/socat
---

# socat

Static build of socat for serial console relay.
