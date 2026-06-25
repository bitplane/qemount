---
title: Compis (Telenova floppy image)
created: 1984
system: Telenova Compis (Sweden)
extensions: [".dsk", ".img"]
aliases:
  - Scandis
related:
  - format/disk/raw
---

# Compis (Telenova floppy image)

A raw, headerless sector image for the floppy drives of the Telenova Compis, a
Swedish educational computer. "Compis" is short for *COMPuter I Skolan*
("computer in school"); it was procured for Swedish schools and shipped from
1984, and was also sold in Denmark, Finland and Norway under the name *Scandis*.
The machine used an Intel 80186 running CP/M-86 with dual 5.25" floppy drives.

## Geometry

The image carries no header. MAME selects the geometry by matching the file
size against a table of known PC-style MFM formats, all with 512-byte sectors:

| Capacity | Tracks | Sides | Sectors/track |
|----------|--------|-------|---------------|
| 320 KB | 40 | 2 | 8 |
| 360 KB | 40 | 2 | 9 |
| 640 KB | 80 | 2 | 8 |
| 720 KB | 80 | 2 | 9 |
| 1200 KB | 80 | 2 | 15 |

Because there is no container header or magic, the format is identified by file
size, geometry, and the `.dsk`/`.img` extension in context. Several of the gap
sizes are marked "unverified" in the MAME loader.

## References

- MAME loader: [`src/lib/formats/cpis_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/cpis_dsk.cpp)
- [Compis — Wikipedia](https://en.wikipedia.org/wiki/Compis)
- [Telenova Compis — OLD-COMPUTERS.COM Museum](https://www.old-computers.com/museum/computer.asp?st=1&c=358)
