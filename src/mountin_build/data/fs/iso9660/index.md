---
format: fs/iso9660
requires:
  - docker:builder/disk/alpine
  - data/templates/basic.tar
provides:
  - data/fs/basic.iso9660
  - data/fs/basic.rock-ridge.iso9660
  - data/fs/basic.joliet.iso9660
---

# ISO 9660 Test Images

Three independent images populated from the standard template:

- plain ISO 9660 without naming extensions;
- ISO 9660 with Rock Ridge;
- ISO 9660 with Joliet.

Keeping the extensions separate ensures a reader cannot accidentally satisfy
both extension tests through the same hybrid image.
