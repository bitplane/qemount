---
format: fs/coco-rsdos
requires:
  - docker:builder/disk/debian
  - data/templates/basic.tar
provides:
  - data/fs/basic.coco-rsdos
---

# RS-DOS Test Image

A Tandy CoCo RS-DOS (Disk BASIC) filesystem on the standard 35-track,
single-sided 5.25" layout (161,280 bytes), built by packing the `basic`
template into a fresh disk. RS-DOS is flat, so the template tree is flattened
and names are sanitised to 8.3.

This is a test-fixture generator for future RS-DOS detection work, not a reader:
qemount defers filesystem reading to the original system in an emulator.
`mkrsdos.py` is a general-purpose RS-DOS mkfs (`mkrsdos.py OUTPUT.dsk SRC_DIR`)
and verifies each image by reading the whole directory back, byte-for-byte,
before writing it out.
