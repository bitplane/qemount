---
title: Apollo/Domain disk image
created: unknown
system: Apollo/Domain workstation
extensions: [".afd"]
related:
  - format/disk/raw
---

# Apollo/Domain disk image

A raw, headerless sector image of a floppy from an Apollo/Domain workstation —
the 68000-based engineering workstations built by Apollo Computer in the 1980s
(later acquired by HP), which ran the Domain/OS (Aegis) operating system.

## Geometry

Fixed geometry, MFM encoding (handled via the uPD765 floppy controller format):

| Property | Value |
|----------|-------|
| Tracks | 77 |
| Sides | 2 |
| Sectors / track | 8 |
| Bytes / sector | 1024 |
| Total | ~1.26 MB |

The image has no header. MAME notes its gap sizes are unverified.

## References

- MAME loader: [`src/lib/formats/apollo_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/apollo_dsk.cpp)
- [Apollo/Domain — Wikipedia](https://en.wikipedia.org/wiki/Apollo_Computer)
