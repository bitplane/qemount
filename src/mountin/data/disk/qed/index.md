---
format: disk/qed
requires:
  - docker:builder/disk/debian
build_requires:
  - data/pt/hybrid.gpt
provides:
  - data/disk/hybrid.qed
---

# QED Test Image

QEMU QED (deprecated) disk image containing hybrid GPT/MBR partition table.
