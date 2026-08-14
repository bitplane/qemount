---
title: illumos qemount QEMU boot adapter
output_platforms:
  x86_64-illumos:
    provides:
      - bin/qemu/${OUTPUT_PLATFORM}/illumos/qemount/boot/xplatform/i86pc/kernel/amd64/unix
requires:
  - bin/qemu/${OUTPUT_PLATFORM}/illumos/qemount/kernel/unix
---

# illumos qemount QEMU boot adapter

A small Multiboot 1 prefix which adapts QEMU's kernel and initrd command lines
to the canonical names expected by illumos dboot. The illumos kernel image
itself is appended unchanged.
