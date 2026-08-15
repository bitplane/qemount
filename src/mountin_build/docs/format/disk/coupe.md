---
title: SAM Coupé MGT disk image
created: 1989
system: SAM Coupé
extensions: [".mgt", ".dsk"]
aliases:
  - MGT disk
  - SAMDOS disk
related:
  - format/disk/raw
---

# SAM Coupé MGT disk image

A raw, headerless sector dump of a SAM Coupé floppy, named after Miles Gordon
Technology (MGT), the British company that produced the SAM Coupé (1989) and the
earlier +D/DISCiPLE ZX Spectrum interfaces. The same MGT layout is used by those
Spectrum interfaces. The image is a flat, linear sequence of sectors with no
metadata; it cannot represent copy-protection or non-standard tracks (the
headered EDSK format is used for those).

## Geometry

The image has no header; geometry is fixed by size:

| Capacity | Tracks | Sides | Sectors | Bytes/sector | Encoding |
|----------|--------|-------|---------|--------------|----------|
| 720 KB | 80 | 2 | 9 | 512 | MFM DD |
| 800 KB | 80 | 2 | 10 | 512 | MFM DD |

The common SAM disk is the 10-sector image at 819,200 bytes (512 × 10 × 2 × 80);
the 9-sector image is 737,280 bytes. Older images sometimes carry the generic
`.dsk` extension instead of `.mgt`.

## References

- MAME loader: [`src/lib/formats/coupedsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/coupedsk.cpp)
- [SAMdisk formats — Simon Owen](https://simonowen.com/samdisk/formats/)
- [SimCoupe manual — disk formats](https://github.com/simonowen/simcoupe/blob/main/Manual.md)
