---
format: fs/atari-dos
requires:
  - docker:builder/disk/debian
  - data/templates/basic.tar
provides:
  - data/fs/basic.atari-dos
---

# Atari DOS Test Image

An Atari DOS 2.0S single-density filesystem on the standard 720-sector,
128-byte-per-sector layout (92,160 bytes, raw sector image), built by packing
the `basic` template into a fresh disk. Atari DOS 2 is flat, so the template
tree is flattened and names are sanitised to 8.3.

This is the raw inner filesystem (the ATR container wrapper is a separate, future
`disk/atr` layer). It is a test-fixture generator for future Atari DOS detection
work, not a reader: qemount defers filesystem reading to the original system in
an emulator.

`mkataridos.py` is a general-purpose, dependency-free Atari DOS tool that also
supports DOS 2.5 enhanced density and ATR output, plus `list`/`extract`
subcommands (`mkataridos.py create [--density sd|ed] OUTPUT SRC_DIR`). It
verifies each image by reading the whole directory back, byte-for-byte, before
writing it out; its output is independently validated against jhallen/atari-tools.
