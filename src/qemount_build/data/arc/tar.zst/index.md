---
format: arc/tar
requires:
  - docker:builder/disk/alpine
  - data/templates/basic.tar
provides:
  - data/arc/basic.tar.zst
---

# tar.zst Test Archive

Test archive in tar.zst (Zstandard) format.
