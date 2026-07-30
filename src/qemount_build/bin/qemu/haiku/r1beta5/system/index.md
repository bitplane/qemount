---
title: Haiku R1 Beta 5 Minimum System
provides:
  - bin/qemu/${ARCH}-haiku/r1beta5/system/haiku-minimum.image
---

# Haiku R1 Beta 5 Minimum System

Builds Haiku's unchanged `@minimum-raw` target. Guest-specific programs and
startup configuration are added in a separate stage so the upstream system
build remains reusable.
