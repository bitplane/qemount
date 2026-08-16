---
title: illumos mountin Appliance
output_platforms:
  x86_64-illumos:
    provides:
      - bin/qemu/${OUTPUT_PLATFORM}/2026-08-13/kernel
      - bin/qemu/${OUTPUT_PLATFORM}/2026-08-13/rootfs.iso
env:
  BUILDER: builder/disk/guest
  ILLUMOS_BUILDER: builder/compiler/illumos/2026-08-13
requires:
  - docker:${BUILDER}
  - docker:${ILLUMOS_BUILDER}
  - bin/${OUTPUT_PLATFORM}/mountin-init
  - bin/${OUTPUT_PLATFORM}/mountin-bootstrap
  - bin/${OUTPUT_PLATFORM}/9d
---

# illumos mountin Appliance

Minimal source-built illumos appliance for QEMU. The kernel boots the HSFS
root module, discovers attached block devices, mounts supported volumes beneath
`/mnt`, and serves that namespace over its second serial port using 9d.

The published pair are both direct QEMU inputs. Kernel, module and sysroot
intermediates remain inside the versioned toolbox and appliance build stages.
