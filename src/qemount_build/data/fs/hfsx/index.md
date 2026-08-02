---
format: fs/hfsplus
requires:
  - docker:builder/disk/qemu
  - data/templates/basic.tar
  - bin/qemu/${HOST_ARCH}-linux/6.12/boot/kernel
  - bin/qemu/${HOST_ARCH}-linux/6.12/boot/rootfs.img
provides:
  - data/fs/basic.hfsx
---

# HFSX Test Image

Case-sensitive HFS Plus test image with the `HX` volume signature. It contains
`case.txt` and `CASE.txt` with different contents to exercise case-sensitive
lookup.
