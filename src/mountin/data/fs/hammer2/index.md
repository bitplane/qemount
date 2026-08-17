---
format: fs/hammer2
requires:
  - docker:builder/disk/guest
build_requires:
  - guest/x86_64-dragonfly/6.4.2/dragonfly.iso
  - data/templates/basic.tar
provides:
  - data/fs/basic.hammer2
---

# HAMMER2 Test Image

Sparse HAMMER2 filesystem populated and verified using the native DragonFly
formatter. Reduced boot and auxiliary reservations keep the fixture compact
without changing its on-disk format.
