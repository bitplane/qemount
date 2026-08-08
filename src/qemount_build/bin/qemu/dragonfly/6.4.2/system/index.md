---
title: DragonFly BSD 6.4.2 system
output_platforms:
  x86_64-dragonfly:
    provides:
      - bin/qemu/${OUTPUT_PLATFORM}/6.4.2/system/dragonfly.iso
---

# DragonFly BSD 6.4.2 system

Source-built serial appliance for DragonFly filesystem support. The build uses
a dedicated QEMU kernel and assembles an allowlisted root from the DragonFly
world, including only the filesystem tools, mount helpers and shared libraries
needed at runtime.

The ISO is limited to 16 MiB so unrelated world or kernel content cannot creep
back into the appliance unnoticed.
