---
title: PureDarwin 17.4 guest system
env:
  MOUNTIN_BUILDER: builder/compiler/puredarwin/17.4
requires:
  - docker:${MOUNTIN_BUILDER}
provides:
  - guest/${MOUNTIN_TARGET_PLATFORM}/17.4/system
---

# PureDarwin 17.4 guest system

Source-built base system and boot closure exported from the matching compiler
toolbox for appliance assembly.
