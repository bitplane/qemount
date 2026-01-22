---
format: disk/vmdk
requires:
  - docker:builder/disk/debian
build_requires:
  - data/pt/hybrid.gpt
provides:
  - data/disk/hybrid.vmdk
---

# VMDK Test Image

VMware VMDK disk image containing hybrid GPT/MBR partition table.
