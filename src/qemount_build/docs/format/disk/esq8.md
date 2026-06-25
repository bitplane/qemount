---
title: Ensoniq 8-bit instrument disk (Mirage / SQ-80)
created: unknown
system: Ensoniq Mirage / SQ-80
extensions: [".img"]
aliases:
  - esq8
  - Ensoniq Mirage disk image
  - Ensoniq SQ-80 disk image
related:
  - format/disk/esq16
  - format/disk/raw
---

# Ensoniq 8-bit instrument disk (Mirage / SQ-80)

A decoded sector image of the 3.5-inch floppies used by Ensoniq's 8-bit
instruments: the Mirage sampler (1984) and the SQ-80 cross-wave synthesizer
(1987). These machines store their samples, programs and sequences on PC-style
MFM floppies, but with an unusual mixed-size sector layout, so the image is a
flat dump of those sectors rather than a generic 720 KB/1.44 MB PC disk. It is
the 8-bit counterpart to the [16-bit Ensoniq disk](esq16) used by the later
VFX-SD, SD-1 and EPS-16.

## Geometry

| Property | Value |
|----------|-------|
| Tracks | 40 |
| Sides | 1 (Mirage) or 2 (SQ-80) |
| Sectors / track | 6 |
| Sector sizes | sectors 0–4 are 1024 bytes, sector 5 is 512 bytes |
| Track capacity | 5 × 1024 + 512 = 5632 bytes |
| Encoding | PC MFM |

MAME builds each track as standard PC MFM and identifies the image by matching
the exact byte count (5632 bytes per track × the track count) rather than by any
signature — the image is headerless. The distinctive part is the per-track sector
map: five full 1 KB sectors numbered 0–4 followed by a single half-size 512-byte
sector with ID 5.

Independent documentation of the on-disk layout (Gary Giebler's notes and the
Mirage disk-format write-ups) describes the same scheme: 80 logical tracks
numbered 0–79 on a single-sided Mirage disk, each with five 1024-byte sectors and
one 512-byte sector. The Mirage records single-sided; the SQ-80 uses both sides.

## References

- MAME source: [`src/lib/formats/esq8_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/esq8_dsk.cpp)
  — "PC MFM, 40 tracks, single (Mirage) or double (SQ-80) sided, 6 sectors per
  track; sectors 0–4 are 1024 bytes, sector 5 is 512 bytes."
- [Ensoniq Floppy Diskette Formats (Gary Giebler) — deepsonic.ch](https://www.deepsonic.ch/deep/docs_manuals/ensoniq_floppy_diskette_formats.pdf)
- [Ensoniq Mirage Disk Format — youngmonkey.ca](http://www.youngmonkey.ca/nose/audio_tech/synth/Ensoniq-Mirage_DiskFormat.html)
- [Ensoniq Mirage — Wikipedia](https://en.wikipedia.org/wiki/Ensoniq_Mirage)
