---
title: HTI (HP tape minicartridge image)
created: 2017
system: HP 9845 / 9825 / 9835 / HP 85 (DC100 tape cartridge)
extensions: [".hti"]
aliases:
  - HP Tape Image
  - HP Tape Minicartridge Image
  - TACO tape image
related:
  - format/fs/hp-lif
  - format/fs/hp98x5
  - format/disk/hpi
  - format/media/csw
---

# HTI (HP tape minicartridge image)

HTI is the tape-image format used by MAME and the HP 9845 emulation project to
preserve the contents of HP's DC100 data minicartridges — the streaming tape
medium of HP's 1970s/early-1980s desktop computers (the 9825, 9835, 9845, and
HP 85, among others). The name is generally expanded as "HP Tape (Mini)cartridge
Image". The cartridges were driven by HP's "TACO" tape controller chip, whose
name survives in the format's original signature.

This is a media-level capture, not a mountable filesystem: it records the
tape's encoded contents for identification and emulation. It is catalogued here
for cross-reference; there is no qemount driver. (The files written to such a
tape are typically HP LIF or 98x5-format records — see `format/fs/hp-lif` and
`format/fs/hp98x5`.)

## Structure

The file is a sequence of track records rather than a flat dump. According to
MAME's loader, the payload is organised as blocks each carrying a 32-bit
little-endian word count, a 32-bit little-endian tape position, and a run of
16-bit data words; a `0xFFFFFFFF` marker terminates a track. The encoding models
the physical tape, distinguishing delta-modulation and Manchester-modulation
schemes and accounting for the differing physical lengths of 0- and 1-bits.

MAME recognises three on-file signatures (32-bit big-endian) at the start:
`TACO` (`0x5441434F`) for the original format, `HTI0` (`0x48544930`) for the
delta-modulation revision, and `HTI1` (`0x48544931`) for the Manchester
revision. As the exact signature words are documented only by MAME's source,
this is recorded here as descriptive detail rather than as a verified detection
rule.

## References

- MAME loader: [`src/lib/formats/hti_tape.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/hti_tape.cpp)
- [Tutorial on Saving Tapes — The HP 9845 Project](https://www.hp9845.net/9845/tutorials/savetapes/)
- [HP 9845 Emulator — The HP 9845 Project](https://www.hp9845.net/9845/projects/emulator/)
- [HP DC100 — Wikipedia](https://en.wikipedia.org/wiki/HP_DC100)
