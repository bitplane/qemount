---
format: fs/hfsplus
requires:
  - docker:builder/disk/qemu
  - data/templates/basic.tar
  - guest/${MOUNTIN_BUILD_ARCH}-linux/6.12/kernel
  - guest/${MOUNTIN_BUILD_ARCH}-linux/base/rootfs.img
provides:
  - data/fs/basic.hfsx
---

# HFSX Test Image

Case-sensitive HFS Plus test image with the `HX` volume signature. It contains
`case.txt` and `CASE.txt` with different contents to exercise case-sensitive
lookup.
