---
title: 9pfuse
requires:
  - docker:${BUILDER}
  - sources/9pfuse-qemount-0.4.tar.gz
provides:
  - bin/${OUTPUT_ARCH}-linux-${ENV}/9pfuse
---

# 9pfuse

Static build of 9pfuse - a FUSE client for the 9P protocol. Its `-n` option
limits the number of outstanding requests for constrained transports.
