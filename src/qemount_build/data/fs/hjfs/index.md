---
format: fs/hjfs
requires:
  - docker:builder/disk/9front
build_requires:
  - bin/qemu/x86_64-9front/qemount/system/9front.iso
  - data/templates/basic.tar
provides:
  - data/fs/basic.hjfs
---

# HJFS Test Image

Raw HJFS image populated from the standard test-data template. The native
9front file server reams, mounts, populates and traverses the fixture before it
is returned.

