---
format: fs/hp-lif
requires:
  - docker:builder/disk/debian
  - data/templates/basic.tar
provides:
  - data/fs/basic.hp-lif
---

# HP LIF Test Image

An HP LIF (Logical Interchange Format) volume on a 270 KB (1056 x 256-byte
block) medium, built by packing the `basic` template into a fresh volume. LIF is
a flat, single-directory format with contiguous file allocation and no
subdirectories, so the template tree is flattened and names are sanitised to 10
characters.

This is a test-fixture generator for future LIF detection work (the volume opens
with the big-endian `0x8000` system word), not a reader: qemount defers
filesystem reading to the original system in an emulator. LIF is block-granular
- it stores file length only in whole 256-byte blocks - so files are stored
zero-padded to a block boundary. `mkhplif.py` is a general-purpose LIF mkfs
(`mkhplif.py OUTPUT.lif SRC_DIR`) and verifies each image by reading the whole
directory back, block-for-block, before writing it out.
