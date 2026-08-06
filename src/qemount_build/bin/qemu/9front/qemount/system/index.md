---
title: 9front qemount system
output_platforms:
  x86_64-9front:
    provides:
      - bin/qemu/${OUTPUT_PLATFORM}/qemount/system/9front.iso
requires:
  - sources/9front-11957.amd64.qcow2.gz
  - sources/9front-qemount.tar.gz
---

# 9front qemount system

Source-built amd64 9front appliance. It boots headlessly on its first serial
port, mounts the single attached FAT filesystem with `dossrv`, and serves that
filesystem with 9front's native `exportfs` over the second serial port.

Official build 11957 is used only as the declared stage-0 compiler
environment.
