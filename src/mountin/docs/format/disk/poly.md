---
title: Poly CP/M Disk Image
created: 1981
system: Poly-1 / Proteus server (New Zealand)
extensions: [".cpm"]
aliases: [Poly CP/M, Polycorp Poly, Proteus, poly_dsk]
related:
  - format/disk/flex
  - format/fs/cpm
---

This `.cpm` file is a floppy image holding a CP/M-formatted disk from the
Poly-1, a New Zealand educational computer. The Poly-1 was designed around 1980
at Wellington Polytechnic and built from 1981 by Polycorp (a DFC New
Zealand / Progeni Systems venture); the Department of Education contracted for
large quantities for schools. The Poly machines were typically diskless
token-ring clients of a shared file server, the **Proteus**, which carried the
8-inch floppy drives (Western Digital 1771 controller, dual 6809/Z80 CPUs) and
could run CP/M, FLEX or the Poly's own POLYSYS. MAME splits these: this loader
handles the CP/M disks, while the FLEX-POLYSYS variants are handled by
`flex_dsk`.

## Structure

MAME selects one of three fixed geometries from the image size:

- 622,592 bytes — 3" DS/SD, 76 tracks, 2 heads, 8 sectors/track, 512-byte sectors
- 256,256 bytes — 8" SS/SD, 77 tracks, 1 head, 26 sectors/track, 128-byte sectors
- 630,784 bytes (default) — 8" DS/SD, 77 tracks, 2 heads, 8 sectors/track,
  512-byte sectors

To identify an image the loader checks the file size against that set and
inspects the boot sector at offset 0 for a fixed 16-byte 6809 boot-code signature
(beginning `0x86 0xC3 0xB7 ...`, a 6809 `LDA #$C3` / `STA` opening). The body is a
standard CP/M filesystem.

(The exact boot signature and size table are described from the MAME loader only;
independent sources confirm the Poly-1 / Proteus history and its CP/M-on-FLEX
hardware but were not cross-checked at the byte level, so no formal detection rule
is asserted here.)

## References

- MAME source: `src/lib/formats/poly_dsk.cpp`
  (https://github.com/mamedev/mame/blob/master/src/lib/formats/poly_dsk.cpp)
- Poly-1, Wikipedia:
  https://en.wikipedia.org/wiki/Poly-1
- The Polycorp Poly 1, classic-computers.org.nz:
  https://www.classic-computers.org.nz/collection/poly1.htm
- The Poly Computer Resources Page, University of Otago:
  https://www.cs.otago.ac.nz/homepages/andrew/poly/Poly.htm
