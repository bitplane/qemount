---
title: Haiku qemount Appliance System
requires:
  - bin/${OUTPUT_ARCH}-haiku/qemount-init
provides:
  - bin/qemu/${OUTPUT_ARCH}-haiku/qemount/system/haiku.image
---

# Haiku qemount Appliance System

Builds the qemount-owned Haiku appliance profile as a 7 MiB image. The profile
keeps the kernel, boot storage path, supported filesystems and partition maps,
serial driver, and services needed for volume mounting. Desktop applications,
GUI services, kernel networking, fonts, and package-management tools are
omitted.

Guest-specific programs and startup configuration are added in a separate
stage so the system build remains reusable.
