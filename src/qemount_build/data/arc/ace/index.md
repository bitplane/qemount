---
format: arc/ace
requires:
  - docker:builder/disk/debian
  - data/templates/basic.tar
build_requires:
  - sources/acefile-qemount-0.2.tar.gz
provides:
  - data/arc/basic.ace
---

# ACE Test Archive

ACE 2.0 test archive built by the tagged `acefile` LZ77 writer and validated
against both the `acefile` reader and Commandline ACE 2.6. Members which do not
get smaller are stored without compression.
