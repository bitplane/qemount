---
title: simple9p for Haiku
requires:
  - sources/simple9p-qemount-0.3.tar.gz
  - sources/libixp-qemount-0.2.tar.gz
provides:
  - bin/${ARCH}-haiku/simple9p
  - bin/${ARCH}-haiku/simple9p-stream
---

# simple9p for Haiku

POSIX simple9p build for Haiku. It retains both network and connected-stream
transports, links Haiku's system network library, and exports `/` by default.
The stream-only variant omits the socket API and its network-library dependency
for serial appliances.
