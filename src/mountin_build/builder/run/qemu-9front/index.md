---
title: 9front QEMU runner
---

# 9front QEMU runner

Reference launcher for the source-built 9front appliance. On amd64, COM1
carries the headless debug console and COM2 carries native 9P from `exportfs`.
The ARM64 QEMU port has one UART, which carries boot output before being handed
to `exportfs` for 9P.
