---
title: Speccy-DOS SDD disk image
created: unknown
system: ZX Spectrum (SpeccyDOS disk interface)
extensions: [".sdd"]
aliases:
  - SpeccyDOS SDD
  - Speccy-DOS disk image
related:
  - format/disk/scl
---

# Speccy-DOS SDD disk image

A raw, headerless floppy image for **SpeccyDOS**, one of the disk operating
systems/interfaces used on the Sinclair ZX Spectrum and its clones. The `.sdd`
file is a straight dump of the disk's sectors with no container metadata; MAME's
loader simply maps the byte stream onto a fixed track/sector geometry. The
loader was contributed by the emulator developer known as MetalliC.

## Geometry

The image carries no header, so the geometry is inferred from the file size.
MAME recognises five layouts, all with 256-byte sectors:

| Capacity | Tracks | Sides | Encoding |
|----------|--------|-------|----------|
| 640 KB | 80 | 2 | MFM (double density) |
| 640 KB | 80 | 2 | MFM (double density), 3.5" |
| 400 KB | 80 | 2 | FM (single density) |
| 400 KB | 80 | 2 | FM (single density), 3.5" |
| 140 KB | 35 | 1 | MFM (double density) |

Sectors are laid down with an interleave skew rather than in linear order. As a
headerless dump, the format has no magic signature; it is identified by the
`.sdd` extension, its size, and context, so no detection rule is given here.

## References

- MAME loader: [`src/lib/formats/sdd_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/sdd_dsk.cpp)
  ("Speccy-DOS SDD disk images"; five 256-byte-sector geometries, interleaved)
- [ZX Spectrum disk file formats — x128 emulator documentation](https://x128.speccy.cz/x128wip/instructions/fileformats.htm)
  ("SDD — A simple dump of the bytes, used for the SpeccyDOS interface.")
