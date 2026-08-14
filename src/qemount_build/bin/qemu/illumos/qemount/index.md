---
title: illumos qemount Appliance
output_platforms:
  x86_64-illumos:
    provides:
      - bin/qemu/${OUTPUT_PLATFORM}/illumos/qemount/xplatform/i86pc/kernel/amd64/unix
      - bin/qemu/${OUTPUT_PLATFORM}/illumos/qemount/rootfs.iso
env:
  BUILDER: builder/disk/guest
  ILLUMOS_BUILDER: builder/compiler/illumos/qemount-0.1
requires:
  - docker:${BUILDER}
  - docker:${ILLUMOS_BUILDER}
  - bin/${OUTPUT_PLATFORM}/qemount-init
  - bin/${OUTPUT_PLATFORM}/qemount-bootstrap
  - bin/${OUTPUT_PLATFORM}/simple9p
---

# illumos qemount Appliance

Minimal source-built illumos appliance for QEMU. The kernel boots the HSFS
root module, discovers attached block devices, mounts supported volumes beneath
`/mnt`, and serves that namespace over its second serial port using simple9p.

The published pair are both direct QEMU inputs. Kernel, module and sysroot
intermediates remain inside the versioned toolbox and appliance build stages.
