---
format: fs/ufs1
requires:
  - docker:builder/disk/guest
  - bin/qemu/x86_64-illumos/illumos/qemount/system/xplatform/i86pc/kernel/amd64/unix
  - bin/qemu/x86_64-illumos/illumos/qemount/system/rootfs.iso
  - bin/x86_64-illumos/mkfs.ufs
  - bin/x86_64-illumos/ufs-fixture-init
  - data/templates/basic.tar
provides:
  - data/fs/basic.ufs-solaris
---

# Solaris UFS test image

Solaris/illumos UFS1 fixture created and populated by the source-built illumos
formatter inside the minimal illumos guest.
