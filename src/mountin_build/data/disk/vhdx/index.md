---
format: disk/vhdx
requires:
  - docker:builder/disk/debian
build_requires:
  - data/pt/hybrid.gpt
provides:
  - data/disk/hybrid.vhdx
---

# VHDX Test Image

Microsoft VHDX disk image containing hybrid GPT/MBR partition table.
