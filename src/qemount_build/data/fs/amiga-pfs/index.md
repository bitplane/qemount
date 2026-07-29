---
format: fs/amiga-pfs
requires:
  - docker:builder/disk/aros
build_requires:
  - bin/qemu/i386-aros/system/aros.iso
  - data/templates/basic.tar
provides:
  - data/fs/basic.amiga-pfs
---

# PFS Test Image

Raw PFS filesystem populated from the standard test-data template. AROS
formats a temporary RDB partition, copies the template into it, and the builder
exports that exact partition as the canonical raw fixture.
