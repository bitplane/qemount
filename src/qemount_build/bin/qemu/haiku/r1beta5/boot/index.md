---
title: Haiku R1 Beta 5 Guest Image
env:
  BUILDER: builder/disk/haiku
requires:
  - docker:${BUILDER}
  - bin/qemu/${ARCH}-haiku/r1beta5/system/haiku-minimum.image
  - bin/${ARCH}-haiku/simple9p
provides:
  - bin/qemu/${ARCH}-haiku/r1beta5/boot/haiku.image
---

# Haiku R1 Beta 5 Guest Image

Adds simple9p and a boot script to the stock minimum image. At boot Haiku
mounts every filesystem it recognises, then serves the resulting system root
over its second PC serial port.

The serial carrier handles one 9P request at a time. Use `9pfuse -n 1` when
mounting this guest.
