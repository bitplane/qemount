---
title: Apple 3.5" GCR disk (400K/800K)
created: unknown
system: Early Macintosh, Apple IIgs
extensions: [".img", ".po", ".2mg"]
aliases:
  - Apple GCR
  - 2IMG
  - 2MG
related:
  - format/disk/diskcopy42
  - format/disk/woz
  - format/disk/moof
  - format/disk/apple2
  - format/fs/hfs
  - format/disk/raw
---

# Apple 3.5" GCR disk (400K/800K)

A raw sector image of an Apple 3.5" GCR floppy as used by the early Macintosh
and the Apple IIgs. The disk uses **zoned recording** — more sectors on the
outer tracks — and Group Code Recording (GCR), where three data bytes are
nibblised into four bytes on the disk surface.

## Geometry

80 tracks, single- or double-sided (400 KB / 800 KB), 512-byte logical sectors,
with sectors-per-track varying by zone:

| Tracks | Sectors/track |
|--------|---------------|
| 0–15 | 12 |
| 16–31 | 11 |
| 32–47 | 10 |
| 48–63 | 9 |
| 64–79 | 8 |

The same MAME loader also reads two headered relatives: [DiskCopy 4.2](diskcopy42)
and the Apple IIgs **2IMG/2MG** image (which prepends a `2IMG` header to the raw
sectors). The bare GCR image itself is headerless.

## References

- MAME loader: [`src/lib/formats/ap_dsk35.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/ap_dsk35.cpp)
- [Apple GCR / Macintosh 3.5" disk — Wikipedia](https://en.wikipedia.org/wiki/Group_coded_recording#Apple)
