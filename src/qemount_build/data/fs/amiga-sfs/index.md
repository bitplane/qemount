---
format: fs/amiga-sfs
requires:
  - docker:builder/disk/guest
build_requires:
  - bin/qemu/i386-aros/base/aros.iso
  - data/templates/basic.tar
  - data/templates/basic.amiga
provides:
  - data/fs/basic.amiga-sfs
---

# SFS Test Image

Raw SFS0 filesystem populated from the standard test-data template. AROS
formats a temporary RDB partition, copies the template into it, and the builder
exports that exact partition as the canonical raw fixture.
