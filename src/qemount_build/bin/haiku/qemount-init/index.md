---
title: qemount init for Haiku
provides:
  - bin/${OUTPUT_ARCH}-haiku/qemount-init
---

# qemount init for Haiku

Minimal libroot-only supervisor for the Haiku appliance. It mounts filesystems
published under `/dev/disk`, then runs the stream-only simple9p server over the
second serial port.
