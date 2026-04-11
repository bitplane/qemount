---
format: arc/aix-backup
requires:
  - docker:builder/disk/debian
  - data/templates/basic.tar
provides:
  - data/arc/basic.bff
---

# AIX Backup Test Archive

Test archive in AIX backup-by-name (BFF) format, built with a minimal
standalone C implementation of the format writer.
