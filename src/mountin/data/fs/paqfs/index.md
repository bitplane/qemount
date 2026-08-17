---
format: fs/paqfs
requires:
  - docker:builder/disk/9front
build_requires:
  - guest/x86_64-9front/11957/9front.iso
  - data/templates/basic.tar
provides:
  - data/fs/basic.paqfs
---

# PAQFS Test Image

Compressed PAQFS image populated from the standard test-data template. The
fixture is produced and verified with 9front's native `mkpaqfs` and `paqfs`
tools.
