---
title: DragonFly BSD 6.4.2 mountin appliance
output_platforms:
  x86_64-dragonfly:
    provides:
      - bin/qemu/${TARGET_PLATFORM}/6.4.2/system/dragonfly.iso
env:
  BUILDER: builder/disk/guest
requires:
  - docker:${BUILDER}
  - guest/${TARGET_PLATFORM}/6.4.2/dragonfly.iso
---

# DragonFly BSD 6.4.2 mountin appliance

Publishes the reusable source-built guest ISO in the QEMU appliance tree.
