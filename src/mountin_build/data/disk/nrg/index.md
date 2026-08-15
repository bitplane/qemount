---
format: disk/nrg
requires:
  - docker:builder/disk/debian
build_requires:
  - data/media/talking.cdda
  - data/fs/basic.iso9660
provides:
  - data/disk/mixed.nrg
---

# NRG Test Image

Nero Burning ROM disc image containing audio and data tracks.

- Track 1: CDDA audio (talking.cdda)
- Track 2: ISO9660 data (basic.iso9660)
