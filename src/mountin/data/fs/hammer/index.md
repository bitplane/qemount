---
format: fs/hammer
requires:
  - docker:builder/disk/guest
build_requires:
  - guest/x86_64-dragonfly/6.4.2/dragonfly.iso
  - data/templates/basic.tar
provides:
  - data/fs/basic.hammer
---

# HAMMER Test Image

Sparse HAMMER filesystem populated from the standard test-data template. The
native DragonFly formatter creates and verifies the fixture inside the guest.
Its deliberately small undo area keeps this test image practical; it is not a
recommended production layout.
