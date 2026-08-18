---
format: arc/rar
requires:
  - docker:builder/disk/debian
  - bin/${MOUNTIN_BUILD_ARCH}-linux-musl/rars
  - data/templates/basic.tar
provides:
  - data/arc/basic.rar
---

# RAR Test Archive

Test archive in RAR 5 format, created with the free `rars` implementation.
Symlinks from the shared template are omitted because its writer deliberately
refuses to follow them.
