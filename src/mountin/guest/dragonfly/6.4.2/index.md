---
title: DragonFly BSD 6.4.2 guest system
env:
  BUILDER: builder/compiler/dragonfly/6.4.2/x86_64
requires:
  - docker:${BUILDER}
output_platforms:
  x86_64-dragonfly:
    provides:
      - guest/${TARGET_PLATFORM}/6.4.2/dragonfly.iso
---

# DragonFly BSD 6.4.2 system

Source-built reusable guest for DragonFly filesystem support. The build uses
a dedicated QEMU kernel and assembles an allowlisted root from the DragonFly
world, including only the filesystem tools, mount helpers and shared libraries
needed at runtime.

The ISO is limited to 16 MiB so unrelated world or kernel content cannot creep
back into the appliance unnoticed.
