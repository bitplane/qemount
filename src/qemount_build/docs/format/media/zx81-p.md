---
title: Sinclair ZX81 program image (.P)
created: 1981
system: Sinclair ZX81
extensions: [".p", ".81"]
aliases:
  - ZX81 P file
  - P81
related:
  - format/media/tzx
---

# Sinclair ZX81 program image (.P)

A `.P` file is a raw memory dump of a saved **Sinclair ZX81** BASIC program. The
ZX81 (1981, Z80) SAVE routine simply writes out a contiguous block of RAM, and a
`.P` file is exactly those bytes with no added framing — no checksum, no block
table, and (in the plain `.P`/`.81` form) not even the program's name.

The dump begins at address 0x4009 (decimal 16393), which is the `VERSN` system
variable near the start of the ZX81's system area, and runs to the end of the
BASIC variables space. Because the ZX81 keeps everything in one contiguous
region, the captured block therefore contains, in order: the lower part of the
system variables, the tokenised BASIC program, the display file (the screen /
video memory, which on the ZX81 lives inside the saved image and varies in
size), and finally the program's variables (`VARS`). The length to load is taken
from the system variables themselves — `E_LINE`/`0x4014` marks the end address —
so the file size is self-describing rather than fixed. The image is loaded back
to 0x4009, restoring the program ready to run.

MAME's loader also handles the **ZX80** sibling (`.o`/`.80`), which saves from
0x4000, carries no filename and no display file, and takes its length from a
different system-variable offset.

This is a program / memory image with a known internal layout but no mountable
filesystem — catalogue for identification only; there is no driver. (A related
`.P81` variant prepends the filename to the same data.)

## References

- MAME loader: [`src/lib/formats/zx81_p.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/zx81_p.cpp)
- [ZX80 and ZX81 file formats — zasm documentation (kio)](https://k1.spdns.de/Develop/Projects/zasm/Info/O80%20and%20P81%20Format.txt)
- [ZX81: BASIC Programs and File Formats — Bumbershoot Software](https://bumbershootsoft.wordpress.com/2017/03/05/zx81-basic-programs-and-file-formats/)
