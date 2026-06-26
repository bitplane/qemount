---
format: fs/oric-jasmin
requires:
  - docker:builder/disk/debian
  - data/templates/basic.tar
provides:
  - data/fs/basic.oric-jasmin
---

# Oric Jasmin Test Image

An Oric Jasmin (FT-DOS) filesystem on the single-sided 41-track, 17-sector,
256-byte layout (178,432 bytes), built by packing the `basic` template into a
fresh disk. The filesystem is flat, so the template tree is flattened and names
are sanitised to 8.3.

This is a test-fixture generator for future Jasmin detection work, not a reader:
qemount defers filesystem reading to the original system in an emulator.
`mkoricjasmin.py` is a general-purpose Jasmin mkfs
(`mkoricjasmin.py OUTPUT.dsk SRC_DIR`) and verifies each image by reading the
whole directory back (through the directory -> inode -> data-sector indirection),
byte-for-byte, before writing it out. The format is mixed-endian: track/sector
references are big-endian, numeric fields little-endian.
