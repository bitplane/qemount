---
title: socat
requires:
  - docker:${BUILDER}
  - sources/socat-1.7.4.4.tar.gz
provides:
  - bin/${ARCH}-linux-${ENV}/socat
---

# socat

Static build of socat for serial console relay.
