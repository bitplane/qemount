---
title: Nascom (NASDOS / CP/M floppy image)
created: early 1980s
system: Nascom 1/2 (Z80 kit computer, UK)
extensions: [".dsk"]
aliases:
  - NASDOS disk image
  - Nascom CP/M disk
related:
  - format/fs/cpm
  - format/disk/raw
---

# Nascom (NASDOS / CP/M floppy image)

A raw, headerless sector image of a floppy from the Nascom range of British
Z80-based single-board computer kits. The Nascom 1 (1977) and Nascom 2 (1979)
were sold by Nasco / Lucas Logic as build-it-yourself boards; floppy support was
added later through Western Digital 177x-family controllers, running either the
native NASDOS disk operating system or CP/M.

The `.dsk` image is simply a straight dump of the disk's sectors in
cylinder/head/sector order, with no container header or per-sector metadata. The
MAME loader recognises four fixed geometries spanning the two operating systems.

## Geometry

All variants use MFM encoding on 5.25" media via a WD177x-type controller:

| Variant | Tracks | Sides | Sectors/track | Bytes/sector | Total |
|---------|--------|-------|---------------|--------------|-------|
| NASDOS single-sided | 80 | 1 | 16 | 256 | 320 KB |
| NASDOS double-sided | 80 | 2 | 16 | 256 | 640 KB |
| CP/M single-sided | 77 | 1 | 10 | 512 | 385 KB |
| CP/M double-sided | 77 | 2 | 10 | 512 | 770 KB |

Because the format carries no header there are no magic bytes; an image is
recognised by its size/geometry, the `.dsk` extension and context. The CP/M
variants hold a standard [CP/M](../fs/cpm) filesystem; the NASDOS variants hold
the Nascom-native disk filesystem.

## References

- MAME loader: [`src/lib/formats/nascom_dsk.cpp`](https://github.com/mamedev/mame/blob/master/src/lib/formats/nascom_dsk.cpp)
  — four WD177x geometries (80/1/16/256, 80/2/16/256, 77/1/10/512, 77/2/10/512),
  NASDOS and CP/M.
- [Nascom — Wikipedia](https://en.wikipedia.org/wiki/Nascom) — Nascom 1 (1977)
  and Nascom 2 (1979), Z80 kit computers from Nasco / Lucas.
- [Nascom Disk Systems — nascom.info](https://nascom.wordpress.com/nascom/hardware/disk-systems/)
  — the Nascom floppy hardware, NASDOS and CP/M disk operating systems.
</content>
</invoke>
