---
format: disk/parallels
requires:
  - docker:builder/disk/debian
build_requires:
  - data/pt/hybrid.gpt
provides:
  - data/disk/hybrid.parallels
---

# Parallels Test Image

Parallels disk image containing hybrid GPT/MBR partition table.
