---
format: arc/freeze
requires:
  - docker:builder/disk/debian
  - data/templates/basic.tar
build_requires:
  - sources/freeze-2.5.0.tar.gz
provides:
  - data/arc/basic.tar.F
---

# freeze Test Archive

Test archive in Unix freeze (.F) format.
