---
title: simple9p for Haiku
requires:
  - sources/simple9p-qemount-0.5.tar.gz
  - sources/libixp-qemount-0.2.tar.gz
provides:
  - bin/${OUTPUT_ARCH}-haiku/simple9p
---

# simple9p for Haiku

POSIX simple9p build for Haiku, configured for its connected serial stream.
The network transport and Haiku network-library dependency are omitted.
