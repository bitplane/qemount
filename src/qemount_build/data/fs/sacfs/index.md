---
format: fs/sacfs
requires:
  - docker:builder/disk/9front
build_requires:
  - bin/qemu/x86_64-9front/qemount/system/9front.iso
  - data/templates/basic.tar
provides:
  - data/fs/basic.sacfs
---

# SACFS Test Image

Compressed SACFS image populated from the standard test-data template. The
fixture is produced and traversed with 9front's native `mksacfs` and `sacfs`
tools.

