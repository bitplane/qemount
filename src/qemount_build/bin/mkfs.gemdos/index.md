---
title: mkfs.gemdos
requires:
  - docker:builder/compiler/linux/6
provides:
  - bin/${HOST_ARCH}-linux-musl/mkfs.gemdos
---

# mkfs.gemdos

Minimal GEMDOS (Atari TOS) filesystem image creator. Creates FAT12 images
with Atari-specific boot sector conventions (68000 BRA.S instruction,
big-endian BPS, 0x1234 boot checksum).
