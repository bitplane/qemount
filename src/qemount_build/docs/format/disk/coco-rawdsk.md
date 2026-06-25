---
title: Color Computer raw disk image
created: 1981
system: Tandy/TRS-80 Color Computer (CoCo)
extensions: [".raw"]
aliases:
  - CoCo raw disk
related:
  - format/media/coco-cas
  - format/disk/raw
---

# Color Computer raw disk image

A raw, headerless sector dump for the floppy drives of the Tandy/TRS-80 Color
Computer (CoCo), the 6809-based home computer family Tandy sold through Radio
Shack from 1980. The standard RS-DOS disk layout is a single-sided, 35-track
5.25" floppy with 18 sectors of 256 bytes per track, written in MFM
double-density. MAME's loader handles this as a flat track-by-track image with
no metadata, distinct from the headered/flux CoCo image formats (JVC/DSK, DMK,
SDF).

The CoCo's tape counterpart is the cassette image catalogued separately at
[media/coco-cas](../media/coco-cas.md).

## Geometry

The image has no header; geometry is fixed by the variant:

| Capacity | Tracks | Sides | Sectors | Bytes/sector | Encoding |
|----------|--------|-------|---------|--------------|----------|
| ~158 KB | 35 | 1 | 18 | 256 | MFM DD |
| ~180 KB | 40 | 1 | 18 | 256 | MFM DD |

A 35-track image is 161,280 bytes (256 × 18 × 35); a 40-track image is 184,320
bytes. Sectors are physically interleaved on the track.

## References

- MAME loader: [`src/lib/formats/coco_rawdsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/coco_rawdsk.cpp)
- [CoCo Disk BASIC disk structure — Sub-Etha Software](https://subethasoftware.com/2023/04/25/coco-disk-basic-disk-structure-part-1/)
- [Hacking Disk — CoCopedia](https://www.cocopedia.com/wiki/index.php/Hacking_Disk)
