---
format: fs/ufs1
requires:
  - docker:builder/disk/guest
  - guest/x86_64-illumos/2026-08-13/system
  - bin/x86_64-illumos/mkfs.ufs
  - bin/x86_64-illumos/mountin-bootstrap
  - bin/x86_64-illumos/ufs-fixture-init
  - data/templates/basic.tar
provides:
  - data/fs/basic.ufs-solaris
---

# Solaris UFS test image

Solaris/illumos UFS1 fixture created and populated by the source-built illumos
formatter inside the minimal illumos guest.
