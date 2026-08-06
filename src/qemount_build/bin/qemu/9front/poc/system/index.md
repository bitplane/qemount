---
title: 9front source-built system
output_platforms:
  x86_64-9front:
    provides:
      - bin/qemu/${OUTPUT_PLATFORM}/poc/system/9front.iso
requires:
  - sources/9front-11957.amd64.qcow2.gz
  - sources/9front-95ad97b98af078a1ca6a45f76725f6b693fa6795.tar.gz
---

# 9front source-built system

Standard amd64 image rebuilt from pinned source by the native 9front
toolchain. Official build 11957 is used only as the declared stage-0 compiler
environment.
