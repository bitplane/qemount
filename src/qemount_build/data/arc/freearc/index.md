---
format: arc/freearc
requires:
  - docker:builder/disk/debian
  - data/templates/basic.tar
provides:
  - data/arc/basic.freearc
---

# FreeArc Test Archive

Test archive in FreeArc format. Uses the original i386 Linux binary from
SourceForge (FreeArc 0.51) running under 32-bit compat libs.
