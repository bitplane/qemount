---
title: Haiku qemount Appliance
env:
  BUILDER: builder/disk/haiku
requires:
  - docker:${BUILDER}
  - bin/qemu/${OUTPUT_ARCH}-haiku/base/haiku.image
  - bin/${OUTPUT_ARCH}-haiku/simple9p
provides:
  - bin/qemu/${OUTPUT_ARCH}-haiku/qemount/haiku.image
---

# Haiku qemount Appliance

Adds simple9p to the qemount appliance. At boot Haiku
mounts every filesystem it recognises, then serves the resulting system root
over its second PC serial port.

The serial carrier handles one 9P request at a time. Use `9pfuse -n 1` when
mounting this guest.
