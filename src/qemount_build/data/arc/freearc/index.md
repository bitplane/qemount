---
format: arc/freearc
requires:
  - docker:builder/compiler/freearc
  - bin/${HOST_ARCH}-linux-gnu/freearc
  - data/templates/basic.tar
provides:
  - data/arc/basic.freearc
---

# FreeArc Test Archive

Test archive in FreeArc format, created by a native build of FreeArc 0.51.
