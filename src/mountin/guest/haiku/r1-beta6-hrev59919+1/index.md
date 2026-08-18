---
title: Haiku Appliance Base
provides:
  - guest/${TARGET_ARCH}-haiku/r1-beta6-hrev59919+1/haiku.image
---

# Haiku Appliance Base

Builds the mountin-owned Haiku appliance profile as a 7 MiB image. The profile
keeps the kernel, boot storage path, supported filesystems and partition maps,
serial driver, and services needed for volume mounting. Desktop applications,
GUI services, kernel networking, fonts, and package-management tools are
omitted.

The mountin init and transport server are added in a separate stage.
