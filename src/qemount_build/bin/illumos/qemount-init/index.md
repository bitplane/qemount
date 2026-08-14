---
title: qemount init for illumos
output_platforms:
  x86_64-illumos:
    provides:
      - bin/${OUTPUT_PLATFORM}/qemount-init
      - bin/${OUTPUT_PLATFORM}/qemount-bootstrap
env:
  BUILDER: builder/compiler/illumos/qemount-0.1
requires:
  - docker:${BUILDER}
---

# qemount init for illumos

A freestanding bootstrap establishes the standard console descriptors before
executing the libc-based init. The latter owns disk discovery, filesystem
mounting and the serial 9P server lifecycle without requiring SMF or a
general-purpose userland.
