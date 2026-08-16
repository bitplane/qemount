---
title: File Copier
provides:
  - docker:builder/copy
---

# File Copier

Minimal build container for copying existing outputs without changing their
contents. Each provided output declares exactly one required source; the
container receives the requested output paths and copies their sources there.
