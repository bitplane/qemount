---
format: fs/cwfs
requires:
  - docker:builder/disk/9front
build_requires:
  - bin/qemu/x86_64-9front/qemount/system/9front.iso
  - data/templates/basic.tar
provides:
  - data/fs/basic.cwfs
---

# CWFS Test Image

Raw CWFS volume created, populated, stopped and reopened using 9front's native
`cwfs64x` server. It uses the server's simple disk-only configuration rather
than a cached WORM or jukebox arrangement.
