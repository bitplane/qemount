---
title: PureDarwin BIOS Bootloader
env:
  BUILDER: builder/disk/debian
requires:
  - docker:builder/disk/debian
  - sources/aros-ports/grub-2.12.tar.gz
provides:
  - bin/qemu/x86_64-darwin/puredarwin/boot/boot.img
  - bin/qemu/x86_64-darwin/puredarwin/boot/core.img
  - bin/qemu/x86_64-darwin/puredarwin/boot/efiemu64.o
---

# PureDarwin BIOS Bootloader

Builds GRUB's BIOS XNU loader from source. `boot.img` occupies the executable
part of the MBR and loads `core.img` from the post-MBR gap; the latter reads
the appliance's HFS+ partition and starts the 64-bit Darwin kernel directly.
