---
format: fs/vtech
requires:
  - docker:builder/disk/debian
  - data/templates/basic.tar
provides:
  - data/fs/basic.vtech
---

# VTech VZ-DOS Test Image

A VTech VZ-DOS filesystem (Laser 200/210/310, Dick Smith VZ-200/VZ-300) on the
logical 40-track, single-sided, 128-byte-sector layout the filesystem itself
uses (81,920 bytes), built by packing the `basic` template into a fresh disk.
VZ-DOS is flat, so the template tree is flattened and names are sanitised to 8
characters.

This is a test-fixture generator for future VZ-DOS detection work, not a reader:
qemount defers filesystem reading to the original system in an emulator.
`mkvtech.py` is a general-purpose VZ-DOS mkfs (`mkvtech.py OUTPUT.dsk SRC_DIR`)
and verifies each image by reading the whole directory back, byte-for-byte,
before writing it out. The 256-byte-sector `.bin` and GCR-encoded `.dsk`/`.dvz`
container encodings are a separate layer (see `disk/vtech-disk`).
