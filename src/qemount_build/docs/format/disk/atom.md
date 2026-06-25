---
title: Acorn Atom disk image
created: 1980
system: Acorn Atom
extensions: [".40t", ".dsk"]
aliases:
  - Atom DOS image
related:
  - format/media/atom-tap
  - format/disk/acorn
  - format/disk/raw
---

# Acorn Atom disk image

A raw, headerless sector image for the Acorn Atom (1980), Acorn's home computer
that preceded the BBC Micro. With the optional disk pack the Atom drove a 5.25"
floppy through a Western Digital WD177x-series controller, using a DFS-style
layout closely related to the one Acorn later carried into the BBC Micro.

## Geometry

The image is a flat dump of the disk's sectors, with no header or magic:

| Capacity | Tracks | Sides | Sectors/track | Bytes/sector | Encoding |
|----------|--------|-------|---------------|--------------|----------|
| 100 KB | 40 | 1 | 10 | 256 | FM (single density) |

This is the same 100 KB single-sided, single-density geometry as a 40-track
Acorn DFS disc, so an Atom `.40t` image is byte-compatible with a 100 KB `.ssd`
and can simply be renamed. See `disk/acorn` for the wider BBC/Electron DFS and
ADFS image family, and `media/atom-tap` for the Atom's cassette format.

## References

- MAME loader: [`src/lib/formats/atom_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/atom_dsk.cpp)
- [atom disk images in .40t format — stardot.org.uk](https://stardot.org.uk/forums/viewtopic.php?t=24925)
- [Disc Filing System — Wikipedia](https://en.wikipedia.org/wiki/Disc_Filing_System)
