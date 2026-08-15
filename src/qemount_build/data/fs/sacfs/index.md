---
format: fs/sacfs
requires:
  - docker:builder/disk/9front
build_requires:
  - bin/qemu/x86_64-9front/11957/9front.iso
  - bin/x86_64-9front/mksacfs
  - data/templates/basic.tar
provides:
  - data/fs/basic.sacfs
---

# SACFS Test Image

Compressed SACFS image populated from the standard test-data template with
9front's native `mksacfs` tool.
