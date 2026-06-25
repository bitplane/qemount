---
title: Apple II disk images (DSK / DO / PO / NIB)
created: unknown
system: Apple II
extensions: [".dsk", ".do", ".po", ".d13", ".nib", ".edd"]
related:
  - format/disk/apple-gcr
  - format/disk/woz
  - format/disk/agat840k
  - format/disk/raw
---

# Apple II disk images (DSK / DO / PO / NIB)

A family of disk image formats for the Apple II 5.25" floppy. The sector formats
are headerless raw sector dumps that differ only in **sector ordering**; the
nibble formats store the lower-level encoded bitstream. MAME's loader handles
five:

| Variant | Ext | Geometry | Notes |
|---------|-----|----------|-------|
| 13-sector | `.d13` | 35 trk × 13 × 256 (~91 KB) | DOS 3.2 and earlier; sequential order |
| 16-sector DOS | `.dsk`/`.do` | 35 trk × 16 × 256 (~140 KB) | DOS 3.3 sector skew |
| 16-sector ProDOS | `.dsk`/`.po` | 35 trk × 16 × 256 (~140 KB) | ProDOS sector skew |
| NIB | `.nib` | 35–40 trk | nibble-level (raw GCR bitstream) |
| EDD | `.edd` | 35–40 trk | nibble-level (bit-copy dump) |

The `.dsk` extension is ambiguous — DOS vs ProDOS order is distinguished by the
filesystem inside, not by the container.

## References

- MAME loader: [`src/lib/formats/ap2_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/ap2_dsk.cpp)
- [Apple DOS 3.3 / disk formats — Wikipedia](https://en.wikipedia.org/wiki/Apple_DOS)
