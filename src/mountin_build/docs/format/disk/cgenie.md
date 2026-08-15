---
title: EACA Colour Genie floppy image
created: 1982
system: EACA Colour Genie EG2000
extensions: [".dsk"]
aliases:
  - Colour Genie disk
  - Color Genie disk
related:
  - format/media/cgenie-tape
  - format/disk/raw
---

# EACA Colour Genie floppy image

A raw, headerless sector image for the floppy drives of the EACA Colour Genie
EG2000, a Z80-based colour home computer made in Hong Kong by EACA and sold from
1982, mainly in Germany and other parts of Europe. The Colour Genie was closely
related to the TRS-80 clone line (the "Video Genie" / System 80), and its disks
could be read in a TRS-80 drive with appropriate driver settings.

The format is decoded by MAME's `wd177x_format` machinery, reflecting the
machine's WD177x-series floppy controller. The image carries no signature; MAME
selects geometry by matching the file against a table of known configurations.

## Geometry

All variants use 256-byte sectors; single density is FM, double density MFM.

| Type | Capacity | Density | Sides | Tracks | Sectors/track |
|------|----------|---------|-------|--------|---------------|
| A | ~102 KB | SD | 1 | 41 | 10 |
| B | ~204 KB | SD | 2 | 41 | 10 |
| C | ~184 KB | DD | 1 | 42 | 18 |
| D | ~368 KB | DD | 2 | 42 | 18 |
| I | ~204 KB | SD | 1 | 81 | 10 |
| J | ~408 KB | SD | 2 | 81 | 10 |
| K | ~368 KB | DD | 1 | 82 | 18 |
| L | ~736 KB | DD | 2 | 82 | 18 |

## References

- MAME loader: [`src/lib/formats/cgenie_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/cgenie_dsk.cpp)
- [Colour Genie — Wikipedia](https://en.wikipedia.org/wiki/Colour_Genie)
- [EACA Colour Genie — classic-computers.org.nz](https://www.classic-computers.org.nz/system-80/hardware_eaca-colour-genie.htm)
