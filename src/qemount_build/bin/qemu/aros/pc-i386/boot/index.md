---
title: AROS PC i386 Boot ISO
requires:
  - sources/aros-qemount.tar.gz
provides:
  - bin/qemu/${ARCH}-aros/boot/aros.iso
---

# AROS PC i386 Boot ISO

Bootable tiny-variant AROS ISO using the GRUB 2 bootloader. The matching
source-pinned cross-toolchain is supplied by the PC i386 compiler image.
