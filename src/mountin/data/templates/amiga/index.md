---
title: AmigaDOS Test Template
requires:
  - docker:builder/disk/alpine
build_requires:
  - data/templates/basic.tar
provides:
  - data/templates/basic.amiga
---

# AmigaDOS Test Template

AmigaDOS population script derived from the platform-neutral basic template.
It creates arbitrary directory trees, copies regular files, and recreates every
symbolic link with `MakeLink`.

Keeping this derivative in its own stage means changes to Amiga integration do
not invalidate every consumer of `data/templates/basic.tar`.
