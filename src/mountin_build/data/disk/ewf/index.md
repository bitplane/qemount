---
format: disk/ewf
requires:
  - docker:builder/disk/debian
build_requires:
  - data/pt/hybrid.gpt
provides:
  - data/disk/hybrid.E01
---

# EWF Test Image

Expert Witness Format (E01) disk image wrapping a hybrid MBR/GPT disk with
FAT32, ext4, and XFS partitions. Tests recursive detection through the full
chain: EWF container → partition table → filesystems.
