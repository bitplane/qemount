---
title: DCP / DCU disk image
created: unknown
system: NEC PC-98 (Disk Copy Pro)
extensions: [".dcp", ".dcu"]
aliases:
  - DCU
  - Disk Copy Pro image
related:
  - format/disk/d88
  - format/pt/pc98
  - format/disk/raw
---

# DCP / DCU disk image

DCP/DCU is a floppy-disk image format for the NEC PC-98 series, produced by the
DOS utility **Disk Image Pro** (also referred to as "Disk Copy Pro", giving the
`.dcp`/`.dcu` extensions). Rather than being an emulator-native format, it is a
practical imaging container: a short header records the media type and which
tracks are present, then the present tracks' sector data follows.

## Structure

The image begins with a 0xA3-byte header followed by track data (per the MAME
loader):

| Offset | Size | Field |
|--------|------|-------|
| 0x00 | 1 | Media / disk-format type |
| 0x01 | 0xA1 | Track map: one byte per track, 0x01 = present, 0x00 = absent |
| 0xA2 | 1 | "All cylinders stored" flag |
| 0xA3 | — | Track data for the present tracks |

The first byte selects the geometry from a set of PC-98 media types — for
example 2DD 8/9-sector (640/720 KB) and 2HD 8/15/18-sector (1.25/1.21/1.44 MB),
with sector sizes of 128–1024 bytes. There is no magic signature; the format is
identified by extension and the header layout. MAME notes that some images have
faulty track maps and that the HDB (0x11) variant is untested.

## References

- MAME loader: [`src/lib/formats/dcp_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/dcp_dsk.cpp)
- [DCU/DCP File Format — pc98.org](https://www.pc98.org/project/doc/dcp.html)
- [pc98-disk-tools — GitHub](https://github.com/barbeque/pc98-disk-tools)
