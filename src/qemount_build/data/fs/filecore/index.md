---
format: fs/filecore
build_requires:
  - sources/disc-image-manager-1.50.1.tar.gz
requires:
  - docker:builder/disk/debian
  - data/templates/basic.tar
provides:
  - data/fs/basic.filecore
---

# Filecore test image

An ADFS new-map hard-disk image containing the standard test-data tree. It is
created with Disc Image Manager's headless CLI and exercises NetBSD's native
Filecore reader.
