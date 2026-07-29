---
format: fs/highsierra
requires:
  - docker:builder/disk/alpine
  - data/templates/basic.tar
provides:
  - data/fs/basic.highsierra
---

# High Sierra Test Image

High Sierra Format CD-ROM image populated from the standard test-data
template. The builder starts from a plain ISO 9660 image, then converts the
volume descriptors and directory records according to the High Sierra
structures retained by the Linux UAPI.
