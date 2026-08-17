---
format: fs/lfs
requires:
  - docker:builder/disk/netbsd
  - guest/x86_64-netbsd/10.0/boot/boot.img
  - bin/x86_64-netbsd/newfs_lfs
  - data/templates/basic.tar
provides:
  - data/fs/basic.lfs
---

# NetBSD LFS test image

NetBSD's native formatter creates a raw LFS volume inside the mountin NetBSD
guest. The fixture is populated with the standard test-data tree, remounted,
and read back before the build succeeds.
