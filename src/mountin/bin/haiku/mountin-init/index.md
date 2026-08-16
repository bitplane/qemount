---
title: mountin init for Haiku
provides:
  - bin/${OUTPUT_ARCH}-haiku/mountin-init
---

# mountin init for Haiku

Minimal libroot-only supervisor for the Haiku appliance. It mounts filesystems
published under `/dev/disk`, then runs the stream-only 9d server over the
second serial port.
