---
title: illumos qemount root ramdisk
output_platforms:
  x86_64-illumos:
    provides:
      - bin/qemu/${OUTPUT_PLATFORM}/illumos/qemount/rootfs.iso
requires:
  - docker:builder/disk/guest
  - sources/illumos-gate-linux-build.tar.gz
  - bin/qemu/${OUTPUT_PLATFORM}/illumos/qemount/kernel/genunix
  - bin/qemu/${OUTPUT_PLATFORM}/illumos/qemount/kernel/unix
  - bin/qemu/${OUTPUT_PLATFORM}/illumos/qemount/modules
  - bin/qemu/${OUTPUT_PLATFORM}/illumos/qemount/sysroot
  - bin/${OUTPUT_PLATFORM}/qemount-init
  - bin/${OUTPUT_PLATFORM}/qemount-bootstrap
---

# illumos qemount root ramdisk

An ISO 9660 image containing only the qemount kernel, selected modules and
appliance configuration. QEMU supplies it as the Multiboot rootfs module and
illumos mounts it read-only through its native HSFS implementation.

The boot kernel is a small Multiboot 1 adapter followed by the unmodified
illumos ELF image. It corrects QEMU's host-relative kernel pathname before
entering dboot; the real kernel remains at its canonical path in the archive.
