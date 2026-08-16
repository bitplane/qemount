---
title: Wren Executive disk image
created: 1984
system: Wren Executive (Thorn EMI / Wren Computers Ltd, Z80 CP/M Plus)
extensions: [".img"]
aliases:
  - Wren
  - Wren Executive
related:
  - format/fs/cpm
  - format/disk/kaypro
  - format/disk/raw
---

# Wren Executive disk image

This is the floppy image format for the **Wren Executive System**, a British
"luggable" business computer launched in the summer of 1984. The Wren was built
for Wren Computers Ltd (a joint venture between Transam Microsystems and Prism)
and manufactured at a Thorn EMI plant in Wales. It was a Z80 machine running
CP/M Plus, bundled with the Perfect applications suite, a version of BBC BASIC,
and built-in Prestel/Micronet communications software, all behind a 7-inch
amber monitor in a heavy sheet-metal case. Prism's collapse in 1985 cut
production short, with only around a thousand units believed to have been built.

The machine had twin 5.25-inch floppy drives quoted at 40 tracks and roughly
190 KB per disk. MAME's loader describes a single-sided, double-density 5.25"
disk: 40 cylinders, one head, 10 sectors of 512 bytes per track, MFM encoding,
giving 200 KB of raw sector data (the slightly lower "190 K" figure is the
formatted/usable capacity). The loader is built on MAME's generic Western
Digital WD177x sector-dump framework, which matches the WD-style floppy
controller such CP/M machines used.

The image is a plain, fixed-geometry sector dump with no header or signature:
identification relies on the geometry and on the on-disk CP/M filesystem rather
than on magic bytes. The MAME source notes that the inter-sector gap values are
unverified.

## References

- MAME loader: [`src/lib/formats/wren_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/wren_dsk.cpp)
- [Wren Executive System — Centre for Computing History](https://www.computinghistory.org.uk/det/51455/Wren-Executive-System/)
- [Thorn EMI WREN — old-computers.com museum](https://www.old-computers.com/museum/computer.asp?st=1&c=257)
- [Wren Luggable and Laptops — historictech](https://historictech.com/wren-luggable-and-laptops/)
