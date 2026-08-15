---
title: Casio FZ-1 floppy disk image
created: unknown
system: Casio FZ-1 / FZ-10M / FZ-20M sampler
extensions: [".img"]
aliases:
  - fz1
  - Casio FZ floppy image
related:
  - format/disk/esq8
  - format/disk/raw
---

# Casio FZ-1 floppy disk image

A decoded sector image of the 3.5-inch floppies used by Casio's FZ-series
samplers, the FZ-1 keyboard sampler (1987) and its FZ-10M / FZ-20M rack
counterparts. The machines store sampled waveforms, voices and banks on their
built-in drive, but in a Casio-specific geometry that an ordinary PC drive cannot
read, so the image is a flat dump of those sectors rather than a generic PC
floppy. It is conceptually a sibling of the other vintage-sampler disk dumps such
as the [Ensoniq 8-bit instrument disk](esq8).

## Geometry

| Property | Value |
|----------|-------|
| Form factor | 3.5-inch double-sided |
| Tracks | 80 per side |
| Heads | 2 |
| Sectors / track | 8 |
| Sector size | 1024 bytes |
| Total | 1280 sectors = 1,310,720 bytes (~1.25 MB) |
| Encoding | MFM |
| Rotation | 360 rpm |

MAME builds each track as MFM with these parameters (its gap values are marked
"unverified" in the loader) and identifies the image by its raw byte count rather
than by any signature — the file is headerless. The unusual part is the
combination of 1024-byte sectors, 8 per track, on a double-sided 80-track disk
spun at 360 rpm; the larger sector size and non-PC rotation are why the disks are
unreadable on a standard PC drive without a flux-level reader.

Independent dumps of FZ-1 media corroborate the 1024-byte sector size, the
360 rpm speed and a documented total of 1280 sectors (which equals 80 × 2 × 8,
i.e. 8 sectors per track). One community write-up instead cites 9 sectors per
track; that figure does not reconcile with the 1280-sector total, so this page
follows the 8-sectors-per-track geometry that both MAME and the sector count
agree on.

The image is headerless and shares its `.img` extension with many other raw
sector dumps, so it cannot be identified by extension or signature alone; a
reader must rely on the geometry and the FZ on-disk volume structure.

## References

- MAME source: [`src/lib/formats/fz1_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/fz1_dsk.cpp)
  — name `"fz1"`, "FZ-1 floppy disk image", FF_35 / MFM, 80 tracks, 2 heads,
  8 × 1024-byte sectors per track.
- [Casio FZ-1 disk images — Jacob Vosmaer](https://blog.jacobvosmaer.nl/0057-fz-1-images/)
  and the accompanying [fz1 tools](https://github.com/jacobvosmaer/fz1)
- [Casio FZ-1 — Vintage Synth Explorer](https://www.vintagesynth.com/casio/fz-1)
- [Casio FZ-1 disk format discussion — YamahaMusicians forum](https://yamahamusicians.com/forum/viewtopic.php?t=18578)
