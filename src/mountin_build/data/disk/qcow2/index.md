---
format: disk/qcow2
requires:
  - docker:builder/disk/debian
build_requires:
  - data/pt/hybrid.gpt
provides:
  - data/disk/hybrid.qcow2
---

# QCOW2 Test Image

QEMU QCOW2 disk image containing hybrid GPT/MBR partition table.
