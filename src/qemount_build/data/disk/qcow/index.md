---
format: disk/qcow
requires:
  - docker:builder/disk/debian
build_requires:
  - data/pt/hybrid.gpt
provides:
  - data/disk/hybrid.qcow
---

# QCOW Test Image

QEMU QCOW (legacy) disk image containing hybrid GPT/MBR partition table.
