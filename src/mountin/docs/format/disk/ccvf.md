---
title: Compucolor Virtual Floppy (CCVF)
created: unknown
system: Compucolor II
extensions: [".ccvf"]
aliases:
  - Compucolor Virtual Floppy Disk Image
related:
  - format/disk/raw
---

# Compucolor Virtual Floppy (CCVF)

A virtual floppy image for the Compucolor II, an integrated colour home computer
sold by Compucolor Corporation from around 1977. The machine stored data on
single-sided 5.25" "mini-floppy" diskettes, and CCVF is the container used by
emulators to preserve those disks.

## Structure

Unlike most disk images, CCVF is a **text file**, not a raw binary sector dump.
It opens with a label line containing the string
`Compucolor Virtual Floppy Disk Image`, followed by lines that carry the disk
contents as ASCII hexadecimal. MAME's loader reads these hex lines (up to 32
bytes / 64 hex characters per line) and reconstructs the track and sector data,
including label and track identifiers.

## Geometry

The encoded disk is single-sided with 128-byte sectors:

| Tracks | Sides | Sectors/track | Bytes/sector | Capacity |
|--------|-------|---------------|--------------|----------|
| 40–41  | 1     | 10            | 128          | ~51 KB/side |

When rebuilt into a real track image, the physical sector order is interleaved
(`0,5,1,6,2,7,3,8,4,9`), with 8N1 byte framing and CRC-checked sectors padded
with sync patterns to fill the track. Disks were single-sided but could be
flipped to use the reverse face.

## References

- MAME loader: [`src/lib/formats/ccvf_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/ccvf_dsk.cpp)
- [Compucolor II virtual media — compucolor.org](https://www.compucolor.org/vmedia.html)
- [Compucolor II technical information — compucolor.org](https://www.compucolor.org/tech.html)
