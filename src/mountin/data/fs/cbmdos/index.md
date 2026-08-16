---
format: fs/cbmdos
requires:
  - docker:builder/disk/debian
  - data/templates/basic.tar
provides:
  - data/fs/basic.cbmdos
---

# CBM DOS Test Image

A Commodore CBM DOS filesystem on the canonical 1541 35-track `.d64` layout
(174,848 bytes, raw sector image), built by packing the `basic` template into a
fresh disk with `cbmconvert` (the standalone Commodore archive tool). CBM DOS is
flat, so the template tree is flattened and the files are written as PRG.

This is a test-fixture generator for CBM DOS detection. The `.d64` is the raw
filesystem image directly (no container header); a future `disk/commodore-cbm`
layer just identifies it by geometry. The image is produced by the canonical
`cbmconvert` tool, so it is a valid CBM DOS disk by construction.
