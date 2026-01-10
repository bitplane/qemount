---
title: Source Downloader
provides:
  - docker:builder/downloader
---

# Source Downloader

Downloads source tarballs from URLs defined in source metadata. Reads META
environment variable to get URLs and output path, tries each URL in order
until one succeeds.
