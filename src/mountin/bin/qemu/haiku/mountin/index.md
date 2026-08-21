---
title: Haiku mountin Appliance
env:
  MOUNTIN_BUILDER: builder/disk/haiku
requires:
  - docker:${MOUNTIN_BUILDER}
  - guest/${MOUNTIN_TARGET_ARCH}-haiku/r1-beta6-hrev59919+1/haiku.image
  - bin/${MOUNTIN_TARGET_ARCH}-haiku/9d
  - bin/${MOUNTIN_TARGET_ARCH}-haiku/mountin-init
provides:
  - bin/qemu/${MOUNTIN_TARGET_ARCH}-haiku/r1-beta6-hrev59919+1/haiku.image
---

# Haiku mountin Appliance

Adds the mountin init and 9d to the base guest. At boot Haiku mounts every
filesystem it recognises, then serves the resulting system root over a
dedicated emulated serial device.

The serial carrier handles one 9P request at a time. Use `9pfuse -n 1` when
mounting this guest.
