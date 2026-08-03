---
format: arc/ace
requires:
  - docker:builder/disk/debian
  - data/templates/basic.tar
provides:
  - data/arc/basic.ace
---

# ACE Test Archive

ACE 2.0 test archive using the format's stored (uncompressed) method. Built by
a small architecture-independent Python writer and validated against both the
`acefile` reader and Commandline ACE 2.6.
