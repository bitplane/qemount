---
title: Haiku mountin Appliance
env:
  BUILDER: builder/disk/haiku
requires:
  - docker:${BUILDER}
  - guest/${TARGET_ARCH}-haiku/r1-beta6-hrev59919+1/haiku.image
  - bin/${TARGET_ARCH}-haiku/9d
  - bin/${TARGET_ARCH}-haiku/mountin-init
provides:
  - bin/qemu/${TARGET_ARCH}-haiku/r1-beta6-hrev59919+1/haiku.image
---

# Haiku mountin Appliance

Adds the mountin init and 9d to the base guest. At boot Haiku
mounts every filesystem it recognises, then serves the resulting system root
over its second PC serial port.

The serial carrier handles one 9P request at a time. Use `9pfuse -n 1` when
mounting this guest.
