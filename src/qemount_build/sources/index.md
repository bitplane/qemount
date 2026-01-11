---
title: Sources
env:
  HOST_ARCH: ${HOST_ARCH}
  ARCH: ${ARCH}
  META: ${META}
requires:
  - docker:builder/downloader
runs_on: docker:builder/downloader
---

# Sources

Downloaded source tarballs and archives. The downloader fetches these from
URLs listed in each source's metadata, trying each URL in order until one
succeeds.
