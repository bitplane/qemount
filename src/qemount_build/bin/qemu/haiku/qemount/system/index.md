---
title: Haiku qemount Minimum System
provides:
  - bin/qemu/${ARCH}-haiku/qemount/system/haiku-minimum.image
---

# Haiku qemount Minimum System

Builds Haiku's `@minimum-raw` target as a 128 MiB image. Guest-specific
programs and startup configuration are added in a separate stage so the system
build remains reusable.
