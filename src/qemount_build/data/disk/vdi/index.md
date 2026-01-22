---
format: disk/vdi
requires:
  - docker:builder/disk/debian
build_requires:
  - data/pt/hybrid.gpt
provides:
  - data/disk/hybrid.vdi
---

# VDI Test Image

VirtualBox VDI disk image containing hybrid GPT/MBR partition table.
