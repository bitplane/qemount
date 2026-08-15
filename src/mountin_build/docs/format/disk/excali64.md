---
title: Excalibur 64 disk image
created: unknown
system: BGR Computers Excalibur 64 (Australia, 1983)
extensions: [".raw"]
aliases:
  - excali64
related:
  - format/disk/raw
---

# Excalibur 64 disk image

A decoded sector image of the 5.25-inch floppies used by the Excalibur 64, a
Z80A-based CP/M home computer sold as a build-it-yourself kit by BGR Computers of
Australia from 1983 to 1984. The machine was a small-volume contemporary of the
Microbee aimed at the Australian educational and business markets; only a few
hundred were sold, so the format is rare. The image is a flat MFM sector dump
with no header, conventionally given a `.raw` extension.

## Geometry

| Property | Value |
|----------|-------|
| Media | 5.25-inch, double-sided double-density |
| Tracks | 80 |
| Sides | 2 |
| Sectors / track | 5 |
| Bytes / sector | 1024 |
| Total | 800 KB |
| Encoding | MFM (WD177x-style controller) |

MAME decodes the image through its WD177x format helper, building standard MFM
tracks. The geometry and gap values come from the MAME loader, which marks the
gap sizes as unverified; the image carries no magic and is identified by its
size and geometry rather than a signature.

The Excalibur 64 system itself is well documented (Wikipedia, the Dontronics
restoration pages, arcade-history). The specific 80-track / 2-side / 5×1024
on-disk layout, however, is described here from the MAME loader only, so no
detection rule is asserted.

## References

- MAME source: [`src/lib/formats/excali64_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/excali64_dsk.cpp)
  — WD177x format, 80 tracks, 2 sides, 5 sectors/track, 1024 bytes/sector,
  800 KB; gap sizes noted as unverified.
- [Excalibur 64 — Wikipedia](https://en.wikipedia.org/wiki/Excalibur_64)
- [1983 Australian Excalibur Computer — dontronics.com](https://www.dontronics.com/excalibur.html)
- [Excalibur 64 (BGR Computers, 1984) — arcade-history.com](https://www.arcade-history.com/?n=excalibur-64&page=detail&id=84467)
