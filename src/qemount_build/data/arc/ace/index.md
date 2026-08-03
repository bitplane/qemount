---
format: arc/ace
requires:
  - docker:builder/disk/debian
  - data/templates/basic.tar
build_requires:
  - sources/acefile-qemount-0.1.tar.gz
provides:
  - data/arc/basic.ace
---

# ACE Test Archive

ACE 2.0 test archive using the format's stored (uncompressed) method. Built by
the tagged `acefile` writer and validated against both the `acefile` reader and
Commandline ACE 2.6.
