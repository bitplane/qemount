---
title: Guest Disk Builder
requires:
  - docker:builder/disk/alpine
provides:
  - docker:builder/disk/guest
---

# Guest Disk Builder

Runs operating-system guests under QEMU to create filesystem fixtures whose
formatters are not available on the container host. The bounded marker helper
captures the serial console and terminates guests after they have flushed and
reported successful completion.
