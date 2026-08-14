---
title: Haiku Appliance Base
requires:
  - bin/${OUTPUT_ARCH}-haiku/qemount-init
provides:
  - bin/qemu/${OUTPUT_ARCH}-haiku/base/haiku.image
---

# Haiku Appliance Base

Builds the qemount-owned Haiku appliance profile as a 7 MiB image. The profile
keeps the kernel, boot storage path, supported filesystems and partition maps,
serial driver, and services needed for volume mounting. Desktop applications,
GUI services, kernel networking, fonts, and package-management tools are
omitted.

The qemount transport server is added in a separate stage.
