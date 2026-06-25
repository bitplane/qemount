---
title: OPD (Opus Discovery floppy image)
created: 1985
system: ZX Spectrum (Opus Discovery interface)
extensions: [".opd", ".opu"]
aliases:
  - Opus Discovery disk image
related:
  - format/disk/scl
  - format/disk/raw
---

# OPD (Opus Discovery floppy image)

A raw, headerless sector image of a floppy as used by the Opus Discovery, a disk
interface for the Sinclair ZX Spectrum released in 1985 by the British firm Opus
Supplies. The Discovery added a 3.5" drive, parallel and joystick ports and other
facilities to the 48K (later 128K) Spectrum, and used its own disk operating
system rather than the more common Beta Disk / TR-DOS ([SCL](scl)) system.

The `.opd` (and `.opu`) image is a flat dump of every sector in track order, with
no container header or per-sector metadata. The MAME loader places sector data at
`((track_count × head) + track) × track_size`, i.e. all of side 0's tracks
followed by all of side 1's.

## Geometry

MFM encoding, 3.5" media, identified by image size:

| Variant | Tracks | Sides | Sectors/track | Bytes/sector | Total |
|---------|--------|-------|---------------|--------------|-------|
| Single-sided | 40 | 1 | 18 | 256 | 180 KB |
| Double-sided | 40 | 2 | 18 | 256 | 360 KB |

Because the format carries no header there are no magic bytes; an image is
recognised by its size/geometry, the `.opd` / `.opu` extension and context. (The
Opus Discovery's standard format command produced 40-track single-sided disks;
double-sided 80-track usage is also documented.) MAME notes its gap parameters as
unverified.

## References

- MAME loader: [`src/lib/formats/opd_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/opd_dsk.cpp)
  — "Sinclair ZX Spectrum / Opus Discovery disk image"; 40/1/18/256 and
  40/2/18/256 MFM geometries, identified by size.
- [Opus Discovery — Spectrum Computing](https://spectrumcomputing.co.uk/entry/1000297/Hardware/Opus_Discovery)
  — 1985 Opus Supplies disk interface for the ZX Spectrum, 3.5" drive.
- [OPUS Discovery Interface — HandWiki](https://handwiki.org/wiki/Engineering:OPUS_Discovery_Interface)
  — interface description and disk format details.
</content>
