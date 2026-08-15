---
format: disk/vhd
requires:
  - docker:builder/disk/debian
build_requires:
  - data/pt/hybrid.gpt
provides:
  - data/disk/hybrid.vhd
---

# VHD Test Image

Microsoft VHD disk image containing hybrid GPT/MBR partition table.
