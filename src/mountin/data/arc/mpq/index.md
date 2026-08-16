---
format: arc/mpq
requires:
  - docker:builder/disk/debian
  - data/templates/basic.tar
build_requires:
  - sources/stormlib-9.31.tar.gz
provides:
  - data/arc/basic.mpq
---

# MPQ Test Archive

Test archive in Blizzard MPQ format, built using StormLib.
