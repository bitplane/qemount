---
title: 9front mountin appliance
output_platforms:
  x86_64-9front:
    provides:
      - guest/${TARGET_PLATFORM}/11957/9front.iso
      - bin/${TARGET_PLATFORM}/mksacfs
  aarch64-9front:
    provides:
      - guest/${TARGET_PLATFORM}/11957/9front.qcow2
      - guest/${TARGET_PLATFORM}/11957/u-boot.bin
      - bin/${TARGET_PLATFORM}/mksacfs
requires:
  - sources/9front-11957.amd64.qcow2.gz
  - sources/9front-11957.tar.gz
---

# 9front guest system

Source-built amd64 and ARM64 9front appliances. Each discovers partitions and
mountable filesystems on the single attached disk and serves the system
namespace with 9front's native `exportfs`. Discovered volumes appear beneath
`/mnt`.

The amd64 appliance boots from an ISO and dedicates its second UART to 9P. The
ARM64 QEMU port boots from its native QCOW2 disk through U-Boot and hands its
single UART from boot logging to 9P once startup is complete.

Official build 11957 is used only as the declared stage-0 compiler
environment. Both target architectures are cross-built by 9front's native
toolchain; normal output filtering selects the host's architecture by default,
while `--output-arch` can request the other one explicitly.
